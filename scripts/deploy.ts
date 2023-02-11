import '/hardhat-ethers';
import { ethers } from "hardhat"

async function main() {
    const DUALNFT = await ethers.getContractFactory("DUALNFT");
    const dualNft = await.deploy()
}