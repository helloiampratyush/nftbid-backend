// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
error nftbid__notZeroPriceNft();
error nftbid__notApprovedByMarketPlace();
error nftbid__notAmountYouHaveBid();
error nftbid__notValidAsk();
error nftbid__notActive();
error nftbid__notOwner();
error nftbid__alreadyListed();
error nftbid__notListed();
error nftbid__winnerIsNotDecidedYet();
error nftbid__ownerCannot();
error nftbid__notYouBidHighest();
error nftbid__invalidPrice();
error nftbid__transactionIncomplete();

contract nftbid {
    //event
    event itemListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 minPrice
    );
    event bidAnnounce(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 minPrice,
        uint256 bidStartTime,
        uint256 bidEndTime,
        address owner
    );
    event bidtime(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address bidder,
        uint256 bidAmount,
        uint256 time
    );
    event bidDone(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address buyer
    );
    //state variable
    struct Listing {
        address seller;
        uint256 minPrice;
    }
    struct Bidd {
        address highestBidder;
        uint256 highestBid;
    }
    struct Timing {
        uint256 bidStartTime;
        uint256 bidEndTime;
    }
    mapping(address => mapping(uint256 => Listing)) private s_listItem;

    mapping(address => uint256) s_amount;
    mapping(address => mapping(uint256 => Bidd)) private s_bidvariable;
    mapping(address => mapping(uint256 => Timing)) private s_timeVariable;

    //modifier
    modifier notListed(
        address nftAddress,
        uint256 tokenId,
        address owner
    ) {
        Listing memory item = s_listItem[nftAddress][tokenId];

        if (item.minPrice > 0) {
            revert nftbid__alreadyListed();
        }
        _;
    }
    modifier isListed(address nftAddress, uint256 tokenId) {
        Listing memory item = s_listItem[nftAddress][tokenId];

        if (item.minPrice <= 0) {
            revert nftbid__notListed();
        }
        _;
    }
    modifier isOwner(
        address nftAddress,
        uint256 toKenId,
        address owner
    ) {
        IERC721 nft = IERC721(nftAddress);

        if (owner != nft.ownerOf(toKenId)) {
            revert nftbid__notOwner();
        }
        _;
    }
    modifier notOwner(
        address nftAddress,
        uint256 toKenId,
        address owner
    ) {
        IERC721 nft = IERC721(nftAddress);
        address Owner = nft.ownerOf(toKenId);
        if (owner == Owner) {
            revert nftbid__ownerCannot();
        }
        _;
    }
    modifier onlyBidWinner(address nftAddress, uint256 tokenId) {
        Bidd memory v1 = s_bidvariable[nftAddress][tokenId];
        if (msg.sender != v1.highestBidder) {
            revert nftbid__notYouBidHighest();
        }
        _;
    }

    //function
    function listItem(
        address nftAddress,
        uint256 tokenId,
        uint256 minPrice
    )
        external
        notListed(nftAddress, tokenId, msg.sender)
        isOwner(nftAddress, tokenId, msg.sender)
    {
        if (minPrice <= 0) {
            revert nftbid__notZeroPriceNft();
        }
        IERC721 nft = IERC721(nftAddress);
        if (nft.getApproved(tokenId) != address(this)) {
            //
            revert nftbid__notApprovedByMarketPlace();
        }
        s_listItem[nftAddress][tokenId] = Listing(msg.sender, minPrice);
        emit itemListed(msg.sender, nftAddress, tokenId, minPrice);
    }

    //bid is started by owner
    function allowBid(
        address nftAddress,
        uint256 tokenId,
        uint256 minPrice,
        uint256 timeOfBid
    )
        external
        isOwner(nftAddress, tokenId, msg.sender)
        isListed(nftAddress, tokenId)
    {
        uint256 bidStartTime = block.timestamp;
        uint256 bidEndTime = bidStartTime + timeOfBid;
        s_timeVariable[nftAddress][tokenId] = Timing(bidStartTime, bidEndTime);
        emit bidAnnounce(
            nftAddress,
            tokenId,
            minPrice,
            bidStartTime,
            bidEndTime,
            msg.sender
        );
    }

    //people will bid (you can not bid more than you have you have to pay to get it ),highestbidder and highest bid will get selected..
    function bidding(
        address nftAddress,
        uint256 tokenId,
        uint256 bidAmount
    ) external notOwner(nftAddress, tokenId, msg.sender) {
        Timing memory t2 = s_timeVariable[nftAddress][tokenId];
        if (
            block.timestamp < t2.bidStartTime && block.timestamp > t2.bidEndTime
        ) {
            revert nftbid__notActive();
        }
        Listing memory s1 = s_listItem[nftAddress][tokenId];
        if (bidAmount < s1.minPrice) {
            revert nftbid__invalidPrice();
        }
        Bidd memory v3 = s_bidvariable[nftAddress][tokenId];

        if (bidAmount > v3.highestBid) {
            v3.highestBid = bidAmount;
            v3.highestBidder = msg.sender;
        }

        s_bidvariable[nftAddress][tokenId] = Bidd(
            v3.highestBidder,
            v3.highestBid
        );

        emit bidtime(
            nftAddress,
            tokenId,
            msg.sender,
            bidAmount,
            block.timestamp
        );
    }

    //bid winner  shall have to pay then nft will transfer to them
    function highestBidderPaid(
        address nftAddress,
        uint256 tokenId
    ) external payable onlyBidWinner(nftAddress, tokenId) {
        Bidd memory v4 = s_bidvariable[nftAddress][tokenId];
        if (msg.value != v4.highestBid) {
            revert nftbid__notAmountYouHaveBid();
        }
        Timing memory t5 = s_timeVariable[nftAddress][tokenId];
        if (block.timestamp < t5.bidEndTime) {
            revert nftbid__winnerIsNotDecidedYet();
        }
        Listing memory burnedAsset = s_listItem[nftAddress][tokenId];
        s_amount[burnedAsset.seller] = s_amount[burnedAsset.seller] + msg.value;
        delete (s_listItem[nftAddress][tokenId]);
        IERC721(nftAddress).safeTransferFrom(
            burnedAsset.seller,
            msg.sender,
            tokenId
        );

        emit bidDone(nftAddress, tokenId, msg.sender);
    }

    function withdraw(uint256 ethAmount) public {
        if ((s_amount[msg.sender] < 0) || (ethAmount > s_amount[msg.sender])) {
            revert nftbid__notValidAsk();
        }
        s_amount[msg.sender] = s_amount[msg.sender] - ethAmount;
        (bool success, ) = payable(msg.sender).call{value: ethAmount}("");
        if (!success) {
            revert nftbid__transactionIncomplete();
        }
    }

    //getter (this thing can be eliminated at time of real deployments(gas cost optimization ) but for test an auditing it is neccesary)
    function getstatusOfList(
        address nftAddress,
        uint256 tokenId
    ) public view returns (Listing memory folks) {
        return s_listItem[nftAddress][tokenId];
    }

    function getGainedProfitAmount() public view returns (uint256) {
        return s_amount[msg.sender];
    }
}
