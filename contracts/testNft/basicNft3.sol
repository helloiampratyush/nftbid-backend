// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BasicNft3 is ERC721 {
  string public constant TOKEN_URI =
    "https://ipfs.io/ipfs/QmcEt9t4GgspHf8Z3sw2RooHHGXvgxLKwcn4smPFxiCEm7?filename=daffy.json";
  uint256 private s_tokenCounter;

  constructor() ERC721("daffy", "loonies") {
    s_tokenCounter = 0;
  }

  function mintNft() public {
    _safeMint(msg.sender, s_tokenCounter);
    s_tokenCounter = s_tokenCounter + 1;
  }

  function tokenURI(
    uint256 tokenId
  ) public view override returns (string memory) {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    return TOKEN_URI;
  }

  function getTokenCounter() public view returns (uint256) {
    return s_tokenCounter;
  }
}
