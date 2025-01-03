import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals, assertStringIncludes } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

const CONTRACT_NAME = "bitcoin-options";

Clarinet.test({
    name: "Ensure that contract owner can update oracle address",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const newOracle = accounts.get("wallet_1")!;

        let block = chain.mineBlock([
            Tx.contractCall(
                CONTRACT_NAME,
                "set-oracle-address",
                [types.principal(newOracle.address)],
                deployer.address
            )
        ]);
        
        assertEquals(block.receipts[0].result, "(ok true)");
    }
});

Clarinet.test({
    name: "Ensure that only oracle can update BTC price",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const oracle = accounts.get("wallet_1")!;
        const user = accounts.get("wallet_2")!;

        // First set the oracle address
        let block = chain.mineBlock([
            Tx.contractCall(
                CONTRACT_NAME,
                "set-oracle-address",
                [types.principal(oracle.address)],
                deployer.address
            )
        ]);

        // Try updating price with unauthorized user
        block = chain.mineBlock([
            Tx.contractCall(
                CONTRACT_NAME,
                "update-btc-price",
                [types.uint(50000)],
                user.address
            )
        ]);
        assertEquals(block.receipts[0].result, `(err u100)`); // ERR_NOT_AUTHORIZED

        // Update price with oracle
        block = chain.mineBlock([
            Tx.contractCall(
                CONTRACT_NAME,
                "update-btc-price",
                [types.uint(50000)],
                oracle.address
            )
        ]);
        assertEquals(block.receipts[0].result, "(ok true)");
    }
});

Clarinet.test({
    name: "Test option creation and validation",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const user = accounts.get("wallet_1")!;

        // First deposit sufficient sBTC for collateral
        let block = chain.mineBlock([
            Tx.contractCall(
                CONTRACT_NAME,
                "deposit-sbtc",
                [types.uint(5000000)], // 5,000,000 satoshis
                user.address
            )
        ]);
        assertEquals(block.receipts[0].result, "(ok true)");

        // Create a valid CALL option
        block = chain.mineBlock([
            Tx.contractCall(
                CONTRACT_NAME,
                "create-option",
                [
                    types.ascii("CALL"),
                    types.uint(45000), // strike price
                    types.uint(1000), // expiry
                    types.uint(10000) // amount
                ],
                user.address
            )
        ]);
        assertEquals(block.receipts[0].result, "(ok u0)"); // First option ID should be 0

        // Try creating option with invalid type (should fail at compile time)
        try {
            block = chain.mineBlock([
                Tx.contractCall(
                    CONTRACT_NAME,
                    "create-option",
                    [
                        types.ascii("PUT1"), // Invalid 4-character string
                        types.uint(45000),
                        types.uint(1000),
                        types.uint(10000)
                    ],
                    user.address
                )
            ]);
            assertEquals(block.receipts[0].result, `(err u100)`); // ERR_NOT_AUTHORIZED
        } catch (e) {
            // Expected to fail due to type constraint
            assertStringIncludes(e.message, "string-ascii 4");
        }

        // Try creating option with insufficient collateral
        block = chain.mineBlock([
            Tx.contractCall(
                CONTRACT_NAME,
                "create-option",
                [
                    types.ascii("CALL"),
                    types.uint(100000), // Very high strike price
                    types.uint(1000),
                    types.uint(10000)
                ],
                user.address
            )
        ]);
        assertEquals(block.receipts[0].result, `(err u107)`); // ERR_INSUFFICIENT_COLLATERAL
    }
});

Clarinet.test({
    name: "Test option exercise functionality",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get("deployer")!;
        const oracle = accounts.get("wallet_1")!;
        const user = accounts.get("wallet_2")!;

        // Set oracle and update price
        let block = chain.mineBlock([
            Tx.contractCall(
                CONTRACT_NAME,
                "set-oracle-address",
                [types.principal(oracle.address)],
                deployer.address
            ),
            Tx.contractCall(
                CONTRACT_NAME,
                "update-btc-price",
                [types.uint(40000)],
                oracle.address
            )
        ]);

        // Deposit sufficient sBTC
        block = chain.mineBlock([
            Tx.contractCall(
                CONTRACT_NAME,
                "deposit-sbtc",
                [types.uint(5000000)], // 5,000,000 satoshis
                user.address
            )
        ]);

        // Create CALL option
        block = chain.mineBlock([
            Tx.contractCall(
                CONTRACT_NAME,
                "create-option",
                [
                    types.ascii("CALL"),
                    types.uint(35000), // strike price below current
                    types.uint(1000),
                    types.uint(10000)
                ],
                user.address
            )
        ]);

        // Update price higher for profitable exercise
        block = chain.mineBlock([
            Tx.contractCall(
                CONTRACT_NAME,
                "update-btc-price",
                [types.uint(45000)],
                oracle.address
            )
        ]);

        // Exercise option
        block = chain.mineBlock([
            Tx.contractCall(
                CONTRACT_NAME,
                "exercise-option",
                [types.uint(0)], // option ID 0
                user.address
            )
        ]);
        assertEquals(block.receipts[0].result, "(ok true)");
    }
});