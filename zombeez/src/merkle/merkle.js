import { whitelist } from "./whitelist";

const { MerkleTree } = require("merkletreejs");
const SHA256 = require("crypto-js/sha256");

const leaves = whitelist.map((x) => SHA256(x.toLowerCase()));
const tree = new MerkleTree(leaves, SHA256);
const root = tree.getRoot().toString("hex");
console.log(root)