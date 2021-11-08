// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';


contract ExtendedNFTTemplate is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Strings for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    // Constants
    uint256 public constant MAX_TOKENS = 5000;
    uint256 public constant RESERVED_TOKENS = 100;
    uint256 public constant PRESALE_PRICE = 25000000000000000; // .025 ether
    uint256 public constant PUBLIC_PRICE = 50000000000000000; // .05 ether
    uint256 public constant FUSION_PRICE = 75000000000000000; // .075 ether
    uint256 public constant MAX_PRESALE_MINT = 5;
    uint256 public constant MAX_MINT = 25;
    uint256 public constant MAX_PER_MINT = 5;
    
    // Set starting index and provenance
    uint256 public startingIndexBlock;
    uint256 public startingIndex;
    string public provenance;
    
    // Setup for 4 contributors
    address[] internal _shareholders = [
        0x04C8a5eB62F208FA2c91d017ee5C60e00F54BcF2,
        0x29c36265c63fE0C3d024b2E4d204b49deeFdD671,
        0x92a7BD65c8b2a9c9d98be8eAa92de46d1fbdefaF,
        0x958C09c135650F50b398b3D1E8c4ce9227e5CCEf
    ];
    uint256[] internal _shares = [20000, 20000, 20000, 40000];
    uint256 private constant baseMod = 100000; // Represents "all" team shares
 
    // Keep track of how many minted
    Counters.Counter private _tokenIds;
    uint256 public reservedClaimed;
    uint256 public numTokensMinted;
    
    // URI / IPFS 
    string private _baseTokenURI;

    // Turning on and off minting / presale / publicsale / fusion
    bool public mintingEnabled; 
    bool public publicSaleStarted;
    bool public presaleStarted;
    bool public fusionIsActive;
    
    // Mappings for whitelist and tracking mints per wallet
    mapping(address => bool) private _presaleEligible;
    mapping(address => uint256) private _totalClaimed;

    // Events to emit
    event PaymentReleased(address to, uint256 amount);
    event BaseURIChanged(string baseURI);
    event ReservedMint(address minter, uint256 amount);
    event PresaleMint(address minter, uint256 amount);
    event PublicSaleMint(address minter, uint256 amount);
    event Fusion(uint256 firstTokenId, uint256 secondTokenId, uint256 fusedTokenId);

    constructor (
        string memory _name, 
        string memory _symbol,
        string memory _uri
    ) 
    ERC721(_name, _symbol)
    {
        _baseTokenURI = _uri;
    }
    
    /* ============= Modifiers ============= */
    modifier whenPresaleStarted() {
        require(presaleStarted, "Presale has not started");
        _;
    }

    modifier whenPublicSaleStarted() {
        require(publicSaleStarted, "Public sale has not started");
        _;
    }

     modifier whenFusionIsActive() {
        require(fusionIsActive, "Public sale has not started");
        _;
    }

    modifier onlyOwnerOrTeam() {
        require(
            _shareholders[0] == msg.sender || _shareholders[1] == msg.sender || 
            _shareholders[1] == msg.sender || _shareholders[3] == msg.sender || owner() == msg.sender,
            "caller is neither Team Wallet nor Owner"
        );
        _;
    }

    /* ============= Presale Handing ============= */
    function addToPresale(address[] calldata addresses) external onlyOwnerOrTeam {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Cannot add null address");
            _presaleEligible[addresses[i]] = true;
            _totalClaimed[addresses[i]] > 0 ? _totalClaimed[addresses[i]] : 0;
        }
    }

    function checkPresaleEligiblity(address addr) external view returns (bool) {
        return _presaleEligible[addr];
    }
 
    /* ============= Token URI ============= */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory newUri) external onlyOwnerOrTeam {
        _baseTokenURI = newUri;
    }
    
    /* ============= Toggle Minting, Presale and Fusion ============= */
    function toggleMinting() external onlyOwnerOrTeam {
        mintingEnabled = !mintingEnabled;
    }
    
    function togglePresaleStarted() external onlyOwnerOrTeam {
        presaleStarted = !presaleStarted;
    }

    function togglePublicSaleStarted() external onlyOwnerOrTeam {
        publicSaleStarted = !publicSaleStarted;
    }
    
    function toggleFusion() external onlyOwnerOrTeam {
        fusionIsActive = !fusionIsActive;
    }

    /* ============= Index hash and provedence ============= */
    function setStartingIndex() public onlyOwnerOrTeam {
        require(startingIndex == 0, "Index is already set");
        require(startingIndexBlock != 0, "Index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_TOKENS;
        // If function is called late
        if (block.number - startingIndexBlock > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % MAX_TOKENS;
        }
        // Prevent default sequence.
        if (startingIndex == 0) {
            startingIndex = 1;
        }
    }
    
    function emergencySetStartingIndexBlock() public onlyOwnerOrTeam {
        require(startingIndex == 0, "Starting index is already set");
        startingIndexBlock = block.number;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwnerOrTeam {
        provenance = provenanceHash;
    }
    
    /* ============= Overrides ============= */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /* ============= Minting Functions ============= */
    function mintPresale(uint256 amount) external payable whenPresaleStarted {
        require(mintingEnabled, "Minting is not available at this time");
        require(amount > 0, "Must mint at least one token");
        require(_presaleEligible[msg.sender], "You are not eligible for the presale");
        require(totalSupply() < MAX_TOKENS, "All tokens have been minted");
        require(amount <= MAX_PRESALE_MINT, "Cannot purchase this many tokens during presale");
        require(totalSupply() + amount <= MAX_TOKENS, "Minting would exceed max supply");
        require(_totalClaimed[msg.sender] + amount <= MAX_MINT, "Purchase exceeds max allowed");
        require(PRESALE_PRICE * amount == msg.value, "ETH amount is incorrect");

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = numTokensMinted + 1;

            numTokensMinted += 1;
            _totalClaimed[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }
        
        // If no starting index, set it.
        if (startingIndexBlock == 0) {
            startingIndexBlock = block.number;
        }

        emit PresaleMint(msg.sender, amount);
    }

    /*
    * Public sale minting
    */
    function publicMint(uint256 amount) external payable whenPublicSaleStarted {
        require(mintingEnabled, "Minting is not available at this time");
        require(amount > 0, "Must mint at least one token");
        require(totalSupply() < MAX_TOKENS, "All tokens have been minted");
        require(amount <= MAX_PER_MINT, "Cannot purchase this many tokens in a transaction");
        require(totalSupply() + amount <= MAX_TOKENS, "Minting would exceed max supply");
        require(_totalClaimed[msg.sender] + amount <= MAX_TOKENS, "Purchase exceeds max allowed per address");
        require(PUBLIC_PRICE * amount == msg.value, "ETH amount is incorrect");

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = numTokensMinted + 1;

            numTokensMinted += 1;
            _totalClaimed[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }
        
        // If no starting index, set it.
        if (startingIndexBlock == 0) {
            startingIndexBlock = block.number;
        }

        emit PublicSaleMint(msg.sender, amount);
    } 

    /*
    * Mint reserved NFTs for giveaways, devs, etc.
    */
    function claimReserved(address recipient, uint256 amount) external onlyOwnerOrTeam {
        require(mintingEnabled, "Minting is not available at this time");
        require(totalSupply() < MAX_TOKENS, "All tokens have been minted");
        require(totalSupply() + amount <= MAX_TOKENS, "Minting would exceed max supply");
        require(reservedClaimed != RESERVED_TOKENS, "Already have claimed all reserved tokens");
        require(reservedClaimed + amount <= RESERVED_TOKENS, "Minting would exceed max reserved tokens");

        uint256 _nextTokenId = numTokensMinted + 1;

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(recipient, _nextTokenId + i);
        }
        numTokensMinted += amount;
        reservedClaimed += amount;
        
        // If no starting index, set it.
        if (startingIndexBlock == 0) {
            startingIndexBlock = block.number;
        }

        emit ReservedMint(msg.sender, amount);
    }

    /* ============= Fusion ============= */
    function fuse(uint256 firstTokenId, uint256 secondTokenId) public payable whenFusionIsActive {
        require(fusionIsActive, "Fusion is inactive");
        require(FUSION_PRICE == msg.value, "Ether value sent is not correct");

        // burn the two tokens being fused
        _burn(firstTokenId);
        _burn(secondTokenId);

        // mint new fused token
        uint256 fusedTokenId = numTokensMinted + 1;
        _safeMint(msg.sender, fusedTokenId);

        emit Fusion(firstTokenId, secondTokenId, fusedTokenId);
    }

    /* ============= Withdraw funds ============= */
    /*
    * Withdraw funds and distribute % to respective contributors
    */
    function withdraw(uint256 amount) public onlyOwnerOrTeam {
        require(address(this).balance >= amount, "Insufficient balance");
        uint256 recepients = _shareholders.length;
        for (uint256 i = 0; i < recepients; i++) {
            uint256 payment = amount * _shares[i] / baseMod;
            Address.sendValue(payable(_shareholders[i]), payment);
            emit PaymentReleased(_shareholders[i], payment);
        }
    }
}