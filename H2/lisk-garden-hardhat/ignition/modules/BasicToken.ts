import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const BasicTokenModule = buildModule("BasicTokenModule", (m) => {
    const initialSupply = 1_000_000;

    const basicToken = m.contract("BasicToken", [initialSupply]);

    return { basicToken };
});

export default BasicTokenModule;