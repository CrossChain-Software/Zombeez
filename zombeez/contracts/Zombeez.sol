// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";


contract MerkleProofVerify {
    function verify(bytes32[] memory proof, bytes32 root)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        return MerkleProof.verify(proof, root, leaf);
    }
}

contract Zombeez is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, MerkleProofVerify {

    event PurchasedNFT (address indexed buyer, uint256 startWith, uint256 batch);

    address payable public deployerWallet;

    uint256 public totalMinted;
    uint256 public burnCount;
    uint256 public totalCount = 10000;
    uint256 public maxBatch = 50;
    uint256 public price = 0.03 * 10**18; // 0.08 eth
    string public baseURI;
    bool private started;
    bool public whitelistEnabled = true;
    bytes32 public immutable override merkleRoot;

    address private core1Address; // dev1: 0x04C8a5eB62F208FA2c91d017ee5C60e00F54BcF2
    uint256 private core1Shares;
    
    address private core2Address; // dev2: 0x29c36265c63fE0C3d024b2E4d204b49deeFdD671
    uint256 private core2Shares;
    
    address private core3Address; // artist1: 0x92a7BD65c8b2a9c9d98be8eAa92de46d1fbdefaF
    uint256 private core3Shares;
    
    address private core4Address; // artist2: 0x958C09c135650F50b398b3D1E8c4ce9227e5CCEf
    uint256 private core4Shares;


    string name = 'Zombeez';
    string symbol = 'ZOMB';

    address[] internal coreAddresses = [
        0x04C8a5eB62F208FA2c91d017ee5C60e00F54BcF2,
        0x29c36265c63fE0C3d024b2E4d204b49deeFdD671,
        0x92a7BD65c8b2a9c9d98be8eAa92de46d1fbdefaF,
        0x958C09c135650F50b398b3D1E8c4ce9227e5CCEf
    ];

    constructor(_baseURI, _addresses, _shares, _merkleroot) ERC721(name, symbol) {
        baseURI = _baseURI;
        merkleRoot = _merkleroot;

        deployerWallet = payable(msg.sender);
        
        for(uint256 i=0; i< 10; i++){
            _mint(_msgSender(), 1 + totalMinted++);
        }
    }

    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function changePrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(_tokenId, _tokenURI);
    }

    function setStart(bool _start) public onlyOwner {
        started = _start;
    }

    function toggleWhitelist() onlyOwner {
        whitelistEnabled = !whitelistEnabled;
    }

    function purchaseNFT(uint256 _batchCount) payable public {
        require(started, "Sale has not started");
        require(verify(msg.sender), "Not included on the whitelist");
        require(_batchCount > 0 && _batchCount <= maxBatch, "Batch purchase limit exceeded");
        require(totalMinted + _batchCount <= totalCount, "Not enough inventory");
        require(msg.value == _batchCount * price, "Invalid value sent");
        

        emit PurchasedNFT(_msgSender(), totalMinted+1, _batchCount);
        for(uint256 i=0; i< _batchCount; i++){
            _mint(_msgSender(), 1 + totalMinted++);
        }
    }

    function walletDistro() public {
        uint256 contract_balance = address(this).balance;
        //require(payable(wallet).send(contract_balance));
        require(payable(core1Address).send( (contract_balance * core1Shares) / 1000));
        require(payable(core2Address).send( (contract_balance * core2Shares) / 1000));
        require(payable(core3Address).send( (contract_balance * core3Shares) / 1000));
        require(payable(core4Address).send( (contract_balance * core4Shares) / 1000));
    }
    
    function distroDust() public {
        walletDistro();
        uint256 contract_balance = address(this).balance;
        require(payable(wallet).send(contract_balance));
    }

    function changeWallet(address payable _newWallet) external onlyOwner {
        wallet = _newWallet;
    }

    function walletInventory(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    /**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0xa5409ec958C83C3f309868babACA7c86DCB077c1)) {     // OpenSea approval
            return true;
        }
        
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function burn(uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
        burnCount++;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}