pragma solidity ^0.5.11;

contract EthCam {
    // 5 min timeout @ 14 sec per block
    uint loginTimeoutInBlocks = 21;

    address public CAMERA;

    address public loggedInUser;
    uint public loggedInBlock;
    uint public nonce;
    bytes32[] public pics;

    constructor(address camera) {
      CAMERA = camera;
    }

    modifier canLogin() {
      if (loggedInUser != address(0)) {
        require(
          loggedInUser != address(msg.sender),
          "You are already logged in."
        )

        require(
          block.number > loggedInBlock + loginTimeoutInBlocks,
          "Someone else is currently logged in. Please wait until the previous timeout expires."
        );

        sendBalanceTo(loggedInUser);
      }
      _;
    }

    modifier canLogout() {
      require(msg.sender == loggedInUser, "You are not logged in.");
      _;
    }

    modifier onlyCamera() {
      require(msg.sender == CAMERA, "Sorry, only cameras can do this.");
      _;
    }

    function getPicsCount() public view returns (uint) {
      return pics.length;
    }

    function login()
      public
      payable
      canLogin
    {
      loggedInUser = msg.sender;
      loggedInBlock = block.number;
      // Load camera up with credits
      // Remainder will be returned upon logout
      CAMERA.transfer(msg.value);
    }

    function logout() public canLogout {
      loggedInUser = address(0);
      loggedInBlock = uint(0);
      nonce = uint(0);
      sendBalanceTo(msg.sender);
    }

    function postPic(bytes32 hash) public onlyCamera {
      pics.push(hash);
    }

    function sendBalanceTo(address user) internal {
      user.transfer(address(this).balance);
    }

    function topUpCamera() public payable {
      CAMERA.transfer(msg.value);
    }
}