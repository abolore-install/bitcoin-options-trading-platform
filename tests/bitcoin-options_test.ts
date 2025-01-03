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