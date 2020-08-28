// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

//import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "./MergeCoin.sol";

contract MergePay is ChainlinkClient {
//tight packing
  struct Deposit {
    uint8 typeOfDesposit;
    uint256 amount;
    uint256 id;
    address sender;
  }


  struct User {
    address account;
    string githubUser;
    bool confirmed;
    bytes32 chainlinkRequestId;
  }

  event DepositEvent(
    uint256 amount,
    uint8 typeOfDesposit,
    uint256 id,
    address sender
  );
  event RegistrationConfirmedEvent(
    address account,
    string githubUser,
    bool confirmed,
    bytes32 chainlinkRequestId
  );

  //Deposit[] private _deposits;
  //User[] private _users;

  mapping (address => Deposit) private addressToDeposit ;
  mapping (address => User) private addressToUser ;

  //MergeCoin _mergeCoin;

  address private clOracle;
  bytes32 private clJobId;
  uint256 private clFee;

  /// @dev Initiates MergeCoin and Chainlink.
  /// @param mergeCoinAddress The contract address of MergeCoin
  constructor(address mergeCoinAddress) public {
    _mergeCoin = MergeCoin(mergeCoinAddress);
    setPublicChainlinkToken();
    clOracle = 0xc99B3D447826532722E41bc36e644ba3479E4365;
    clJobId = "3cff0a3524694ff8834bda9cf9c779a1";
    clFee = 0.1 * 10 ** 18; // 0.1 LINK
  }

  /// @dev Deposit ETH on any pull request or issue on GitHub.
  /// @dev TODO: lock up deposit
  /// @param type Issues = 1, Pull Requests = 2
  /// @param id The node ID of the issue or pr
  function deposit(uint8 typeOfDesposit, uint256 id) external payable {
    require(msg.value > 0, "No ether sent.");

    // find existing deposit
    bool updatedExisting = false;
    if(addressToDeposit[msg.sender]) {
        // add amount to existing deposit
        _deposits[i].amount += msg.value;
        updatedExisting = true;
        emit DepositEvent(
          addressToDeposit[msg.sender].amount,
          addressToDeposit[msg.sender].typeOfDesposit,
          addressToDeposit[msg.sender].id,
          addressToDeposit[msg.sender].sender
        );
    }

    // add new deposit
    if (!updatedExisting) {
      addressToDeposit[msg.sender] =  Deposit(msg.value, type, id, prId, msg.sender);
      //_deposits.push(newDeposit);
      emit DepositEvent(msg.value, type, id, msg.sender);
    }
  }

  /// @dev Verify ownership over GitHub account by checking for a repositry of
  /// @dev githubUser named after msg.sender. Adds user as unconfirmed and sends
  /// @dev a chainlink request, that will be fullfilled in registerConfirm.
  /// @param githubUser The GitHub username to register
  function register(string calldata githubUser) external {
    Chainlink.Request memory request = buildChainlinkRequest(clJobId, address(this), this.registerConfirm.selector);
    request.add("username", githubUser);
    request.add("repo", string(abi.encodePacked(msg.sender)));
    bytes32 requestId = sendChainlinkRequestTo(clOracle, request, clFee);
    addressToUser[msg.sender] = User(msg.sender, githubUser, false, requestId);
  }

  /// @dev Chainlink fullfill method. Sets unconfirmed user to confirmed if repo exists.
  /// @param _requestId The Chainlink request ID
  /// @param confirmed Whether a repo named after the address was found or not
  function registerConfirm(bytes32 _requestId, bool confirmed) external {
    require(confirmed, "Account ownership could not be validated.");
      if (addressToUser[msg.sender].chainlinkRequestId == _requestId) {
        addressToUser[msg.sender].confirmed = true;
      }


    emit RegistrationConfirmedEvent(
      addressToUser[msg.sender].account,
      addressToUser[msg.sender].githubUser,
      addressToUser[msg.sender].confirmed,
      addressToUser[msg.sender].chainlinkRequestId
    );
  }

  /// @dev Send deposit back to sender.
  function refund() external {}

  /// @dev Send deposit to contributor (anyone != deposit.sender).
  /// @param githubuUser The GitHub username of the user who wants to withdraw.
  /// @param type Issues = 1, Pull Requests = 2
  /// @param id The node ID of the issue or pr
  function withdraw(string memory githubUser, uint8 typeOfDesposit, uint256 id) external {
    // checks:
    // provided githubUser has repo with name of msg.sender (proof of github account, can receive funds) [chainlink->repourl->id]
    // pr is merged and pr author is the provided githubUser [chainlink->pr->merged]
      // withdraw everything
    // githubUser is sender of a deposit
      // withdraw only own deposit
    // mint merge coin if withdrawer != deposit owner
  }

  /// @dev Convert address type to string type.
  /// @param _address The address to convert
  /// @returns _uintAsString The string representation of _address
  /*function addressToString(address _address) public pure returns (string memory _uintAsString) {
    uint _i = uint256(_address);
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
    uint k = len - 1;
    while (_i != 0) {
      bstr[k--] = byte(uint8(48 + _i % 10));
      _i /= 10;
    }
    return string(bstr);
  }*/
}
