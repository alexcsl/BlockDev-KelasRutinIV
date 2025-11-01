import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const StandardTokenModule = buildModule("StandardTokenModule", (m) => {

  const name = "Garden Token";
  const symbol = "GDN";
  const decimals = 18;
  const initialSupply = 1_000_000n * 10n**18n; // 1 juta token

  const standardToken = m.contract("StandardToken", [
    name,
    symbol,
    decimals,
    initialSupply,
  ]);

  return { standardToken };
});

export default StandardTokenModule;