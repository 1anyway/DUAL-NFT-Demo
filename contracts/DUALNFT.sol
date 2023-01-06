//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract DUALNFT is ERC721, ERC721URIStorage, Ownable, Pausable{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    
    bool public isAllowListActive = false;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public mintPrice = 0.01 ether;
    uint256 public maxBalance = 5;
    uint256 public maxMint = 1;

    mapping(address => uint8) private _allowList;

    uint256 public immutable interval;
    uint256 public lastTimeStamp;
    string[] IpfsUri = [
        "https://ipfs.io/ipfs/QmYaTsyxTDnrG4toc8721w62rL4ZBKXQTGj9c9Rpdrntou/seed.json",
        "https://ipfs.io/ipfs/QmYaTsyxTDnrG4toc8721w62rL4ZBKXQTGj9c9Rpdrntou/purple-sprout.json",
        "https://ipfs.io/ipfs/QmYaTsyxTDnrG4toc8721w62rL4ZBKXQTGj9c9Rpdrntou/purple-blooms.json"
    ];

    
    constructor(uint256 updateInterval) ERC721("DUALNFT", "NFT") {
        interval = updateInterval;
        lastTimeStamp = block.timestamp;
    }

    function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = numAllowedToMint;
        }
    }

    function numAvailableToMint(address addr) external view returns (uint8) {
        return _allowList[addr];
    }

    function mintAllowList(uint8 numberOfTokens) external payable {
        uint256 totalSupply = _tokenIdCounter.current() + 1;
        require(isAllowListActive, "Allow list is not active");
        require(numberOfTokens <= _allowList[msg.sender], "Exceeded max available to purchase");
        require(totalSupply + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(mintPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");

        _allowList[msg.sender] -= numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            safeMint(msg.sender);
        }
    }
    
    function safeMint(address to) public {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, IpfsUri[0]);
    }

    function saleActive(uint256 numberOfTokens) public payable{
        uint256 totalSupply = _tokenIdCounter.current() + 1;
        require(!paused(), "Public sale is paused!");
        require(numberOfTokens <= maxMint, "");
        require(numberOfTokens + totalSupply <= MAX_SUPPLY, "");
        require(balanceOf(msg.sender) + numberOfTokens <= maxBalance, "");
        require(numberOfTokens * mintPrice <= msg.value, "");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            safeMint(msg.sender);
        }
    }

    function performChange(uint256 _tokenId) external {
        if ((block.timestamp - lastTimeStamp) > interval) {
            lastTimeStamp = block.timestamp;
            growFlower(_tokenId);
        }
    }

    function growFlower(uint256 _tokenId) public {
        if(flowerStage(_tokenId) >= 2){return;}
        // Get the current stage of the flower and add 1
        uint256 newVal = flowerStage(_tokenId) + 1;
        // store the new URI
        string memory newUri = IpfsUri[newVal];
        // Update the URI
        _setTokenURI(_tokenId, newUri);
    }

    // determin the stage of the flower growth
    function flowerStage(uint256 _tokenId) public view returns (uint256) {
        string memory _uri = tokenURI(_tokenId);
        // Seed
        if (compareStrings(_uri, IpfsUri[0])) {
            return 0;
        }
        // Sprout
        if (
            compareStrings(_uri, IpfsUri[1]) 
        ) {
            return 1;
        }
        // Must be a Bloom
        return 2;
    }

    // helper function to compare strings
    function compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    // The following functions is an override required by Solidity.
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    // The following functions is an override required by Solidity.
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _isSale() public onlyOwner {
        _unpause();
    }

    function _unSale() public onlyOwner {
        _pause();
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxBalance(uint256 _maxBalance) public onlyOwner {
        maxBalance = _maxBalance;
    }

    function setMaxMint(uint256 _maxMint) public onlyOwner {
        maxMint = _maxMint;
    }

    function reserve(uint256 n) public onlyOwner {
        for (uint256 i = 0; i < n; i++) {
          safeMint(msg.sender);
        }
    }

    function withdraw(address to) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    } 

}