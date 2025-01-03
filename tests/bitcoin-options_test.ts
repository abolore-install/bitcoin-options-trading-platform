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