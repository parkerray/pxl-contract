/*----------------------------------------------------------------

  ____ _____  _______ _     _        _  _____ ___ ___  _   _ ____  
 |  _ \_ _\ \/ / ____| |   | |      / \|_   _|_ _/ _ \| \ | / ___| 
 | |_) | | \  /|  _| | |   | |     / _ \ | |  | | | | |  \| \___ \ 
 |  __/| | /  \| |___| |___| |___ / ___ \| |  | | |_| | |\  |___) |
 |_|  |___/_/\_\_____|_____|_____/_/   \_\_| |___\___/|_| \_|____/ 


----------------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract Pixellations is ERC721, ERC721URIStorage, Ownable {

    uint256 private tokenCount;
    string[] private opacity = [
            '0.2', '0.2', '0.2', '0.2',
            '0.4', '0.4', '0.4',
            '0.8', '0.8',
            '1'
        ];
    uint256[] private smallStarOptions = [
            32, 40, 48, 56, 64
        ];
    uint256 private redChance = 9995;
    uint256 private purpleChance = 9980;
    uint256 private blueChance = 9950;
    uint256 private yellowChance = 9900;
    
    struct Metadata {
        uint256 redStars;
        uint256 purpleStars;
        uint256 blueStars;
        uint256 yellowStars;
        uint256 bigStars;
        uint256 smallStars;
    }
    
    constructor() ERC721("PixellationsCharlie", "PXL") {
        tokenCount = 1;
    }

    function mint(uint256 quantity) public payable {
        require(tokenCount + quantity <= 1064, "Sold out");
        require(msg.value >= quantity * 10000000000000000, "Not enough ETH sent");

        for (uint256 i = 0; i < quantity; i++) {
            safeMint(msg.sender);
        }
    }

    function safeMint(address to) public onlyOwner {
        _safeMint(to, tokenCount);
        string memory formattedTokenURI = formatTokenURI();
        _setTokenURI(tokenCount, formattedTokenURI);
        tokenCount++;
    }

    function withdrawAll() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    
    function random(uint256 input, uint256 min, uint256 max) public view returns (uint256) {
        uint256 range = max - min;
        return max - (uint256(keccak256(abi.encodePacked(input, msg.sender, tokenCount, block.timestamp))) % range) - 1;
    }
    
    function getColor(uint256 starNumber) internal view returns (string memory) {
        uint256 roll = random(starNumber, 0, 10001);
        
        if (roll > redChance) {
            return '#FF8D8D';
        } else if (roll > purpleChance) {
            return '#D7A4FF';
        } else if (roll > blueChance) {
            return '#7DD0FF';
        } else if (roll > yellowChance) {
            return '#FFE790';
        } else {
            return '#FFF';
        }
        
    }
        
    function formatTokenURI() public view returns (string memory) {
        
        string memory svg = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMidYMid meet" viewBox="0 0 64 64" fill="#000"><rect x="0" y="0" width="64" height="64" fill="#000"></rect>';
        
        Metadata memory metadata = Metadata(0, 0, 0, 0, random(tokenCount, 2, 7), smallStarOptions[random(tokenCount, 0, 4)]);
        
        uint256 bigStarRefX = random(tokenCount * metadata.bigStars, 0, 17) * 2;
        uint256 bigStarRefY = random(tokenCount * metadata.smallStars, 0, 17) * 2;
        uint256 bigStarMaxX = bigStarRefX + 31;
        uint256 bigStarMaxY = bigStarRefY + 31;
        
        for (uint256 i = 0; i < metadata.bigStars; i++) {
            svg = string(
                abi.encodePacked(
                    svg, '<rect x="', uint2str(random((tokenCount + i), bigStarRefX, bigStarMaxX)), '" y="', uint2str(random((tokenCount + i * 2), bigStarRefY, bigStarMaxY)), '" width="2" height="2" fill="#FFF"></rect>'
                    )
                );
        }
        
        for (uint256 i = 0; i < metadata.smallStars; i++) {
            
            uint256 colorComparison = random(i, 0, 10001);
            string memory currentOpacity;
            
            if (colorComparison > redChance) {
                metadata.redStars = metadata.redStars + 1;
                currentOpacity = '1';
            } else if (colorComparison > purpleChance) {
                metadata.purpleStars = metadata.purpleStars + 1;
                currentOpacity = '1';
            } else if (colorComparison > blueChance) {
                metadata.blueStars = metadata.blueStars + 1;
                currentOpacity = '1';
            } else if (colorComparison > yellowChance) {
                metadata.yellowStars = metadata.yellowStars + 1;
                currentOpacity = '1';
            } else {
                currentOpacity = opacity[random(i,0,10)];
            }
            
            svg = string(
                abi.encodePacked(
                    svg, '<rect x="', uint2str(random((i), 0, 64)), '" y="', uint2str(random((tokenCount + i), 0, 64)), '" width="1" height="1" fill="', getColor(i), '" opacity="', currentOpacity, '"></rect>' 
                    )
                );
        }
        
        
        svg = string(abi.encodePacked(svg, '</svg>'));
        
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name": "Pixellation #', uint2str(tokenCount), '",',
                            '"description": "The first Pixellations contract",',
                            '"attributes": [',
                                '{',
                                    '"trait_type": "Big Stars",',
                                    '"value": "', uint2str(metadata.bigStars), '"'
                                '},',
                                '{',
                                    '"trait_type": "Small Stars",',
                                    '"value": "', uint2str(metadata.smallStars), '"'
                                '},',
                                '{',
                                    '"trait_type": "Red Stars",',
                                    '"value": "', uint2str(metadata.redStars), '"'
                                '},',
                                '{',
                                    '"trait_type": "Purple Stars",',
                                    '"value": "', uint2str(metadata.purpleStars), '"'
                                '},',
                                '{',
                                    '"trait_type": "Blue Stars",',
                                    '"value": "', uint2str(metadata.blueStars), '"'
                                '},',
                                '{',
                                    '"trait_type": "Yellow Stars",',
                                    '"value": "', uint2str(metadata.yellowStars), '"'
                                '}',
                            '],',
                            '"image": "data:image/svg+xml;base64,',Base64.encode(bytes(string(abi.encodePacked(svg)))),'"}'
                        )
                    )
                )
            )
        );
    }
    
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    
}
