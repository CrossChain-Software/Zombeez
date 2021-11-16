// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';


contract MerkleProof {
    function verify(bytes32 root, bytes32 leaf, bytes32[] memory proof, uint256[] memory positions) public pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

        if (positions[i] == 1) {
            computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
        } else {
            computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        return computedHash == root;
    }
}

contract Zombeez is ERC721Enumerable, Ownable, MerkleProof {
    using Strings for uint;
    using Address for address;
    using Counters for Counters.Counter;
    
    // Merkle root
    bytes32 public immutable merkleRoot;
    
    // Constants
    uint256 public constant MAX_TOKENS = 8335;
    
    // Prices and max amount allowed to mint
    uint256 public publicPrice = 50000000000000000; // .05 eth
    uint256 public maxMint = 20;
    uint256 public maxPerMint = 10;
    
    // Setup for 4 contributors
    address[4] private _shareholders = [
        0x04C8a5eB62F208FA2c91d017ee5C60e00F54BcF2, 
        0x29c36265c63fE0C3d024b2E4d204b49deeFdD671, 
        0x92a7BD65c8b2a9c9d98be8eAa92de46d1fbdefaF, 
        0x958C09c135650F50b398b3D1E8c4ce9227e5CCEf
    ];
    uint[4] private _shares = [20000, 20000, 20000, 40000];
    uint256 private constant baseMod = 100000;
 
    // Keep track of how many minted
    Counters.Counter private _tokenIds;
    uint256 public numTokensMinted;
    
    // URI / IPFS 
    string public baseTokenURI;

    // Turning on and off minting / presale / publicsale
    bool public publicMintingEnabled; 
    bool public publicSaleStarted;
    
    // Mappings for whitelist and tracking mints per wallet
    mapping(address => uint256) private _totalClaimed;

    // Events to emit
    event BaseURIChanged(string baseURI);
    event PublicSaleMint(address minter, uint256 amount);
    event PresaleMint(address minter, uint256 amount);

    constructor (
        string memory _name,
        string memory _symbol,
        string memory _uri,
        bytes32 _merkleRoot
    ) 
    ERC721(_name, _symbol)
    {
        baseTokenURI = _uri;
        merkleRoot = _merkleRoot;
    }
    
    /* ============= Modifiers ============= */
    
    modifier onlyOwnerOrTeam() {
        require(
            _shareholders[0] == msg.sender || _shareholders[1] == msg.sender || 
            _shareholders[1] == msg.sender || _shareholders[3] == msg.sender || owner() == msg.sender,
            "caller is neither Team Wallet nor Owner"
        );
        _;
    }

    /* ============= Token URI ============= */

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory newUri) external onlyOwnerOrTeam {
        baseTokenURI = newUri;
    }
    
    /* ============= Toggle Minting, Presale and Fusion ============= */

    function publicToggleMinting() external onlyOwnerOrTeam {
        publicMintingEnabled = !publicMintingEnabled;
    } 

    function setPublicPrice(uint256 newPublicPrice) external onlyOwnerOrTeam {
        publicPrice = newPublicPrice;
    }

    function setMaxMint(uint256 newMaxMint) external onlyOwnerOrTeam {
        maxMint = newMaxMint;
    }
    
    function setMaxPerMint(uint256 newPerMaxMint) external onlyOwnerOrTeam {
        maxPerMint = newPerMaxMint;
    }

    /* ============= Verify Merkle to mint for free ============= */
    
    function verifyWhitelist(bytes32[] memory _proof, uint256[] memory _positions) public view returns (bool) {
        bytes32 _leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(merkleRoot, _leaf, _proof, _positions);
    }

    /* ============= Minting Functions ============= */
    // Allows Dizzy Dragons and CryptoToadz to mint for free
    function mintForTokenHolders(uint256 amount, bytes32[] memory _proof, uint256[] memory _positions) external {
        require(verifyWhitelist(_proof, _positions), "Not on the whitelist"); 
        require(amount > 0, "Must mint at least one token");
        require(totalSupply() < MAX_TOKENS, "All tokens have been minted");
        require(amount <= 3, "Cannot purchase this many tokens during 'presale'");
        require(totalSupply() + amount <= MAX_TOKENS, "Minting would exceed max supply");
        require(_totalClaimed[msg.sender] + amount <= maxMint, "Purchase exceeds max allowed");

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = numTokensMinted + 1;

            numTokensMinted += 1;
            _totalClaimed[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }
        emit PresaleMint(msg.sender, amount);

    }

    /*
    * Public sale minting
    */
    function mintPublicSale(uint256 amount) external payable {
        require(amount > 0, "Must mint at least one token");
        require(totalSupply() < MAX_TOKENS, "All tokens have been minted");
        require(amount <= maxPerMint, "Cannot purchase this many tokens in a transaction");
        require(totalSupply() + amount <= MAX_TOKENS, "Minting would exceed max supply");
        require(_totalClaimed[msg.sender] + amount <= MAX_TOKENS, "Purchase exceeds max allowed per address");
        require(publicPrice * amount == msg.value, "ETH amount is incorrect");

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = numTokensMinted + 1;

            numTokensMinted += 1;
            _totalClaimed[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }

        emit PublicSaleMint(msg.sender, amount);
    } 

    /* ============= Withdraw funds ============= */
    /*
    * Withdraw funds and distribute % to respective owners
    */
    function withdraw(uint256 amount) public onlyOwnerOrTeam {
        require(address(this).balance >= amount, "Insufficient balance");
        for (uint256 i = 0; i < 4; i++) {
            uint256 payment = amount * _shares[i] / baseMod;
            Address.sendValue(payable(_shareholders[i]), payment);
        }
    }
}