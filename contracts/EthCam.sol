pragma solidity ^0.5.11;

contract EthCam {
    address public CAMERA;

    address public loggedInUser;
    uint public loggedInBlock;
    uint public nonce;
    bytes32[] public pics;

    constructor(address camera) {
      CAMERA = camera;
    }

    function registerCamera() {
      // camera registers itself??

      // only cameras can register other cameras???
    }

    // 5 min timeout @ 14 sec per block
    uint loginTimeoutInBlocks = 21;

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
      require(msg.sender == loggedInUser, "You are not logged in");
      _;
    }

    function sendBalanceTo(address user) internal {
      user.transfer(address(this).balance);
    }

    function login()
      public
      payable
      canLogin
    {
      loggedInUser = msg.sender;
      loggedInBlock = block.number;
      CAMERA.transfer(msg.value);
    }

    // TODO
    function topUp(address cameraId) {
      // Add money to a camera!!!
    }

    function logout() public canLogout {
      loggedInUser = address(0);
      loggedInBlock = uint(0);
      nonce = uint(0);
      sendBalanceTo(msg.sender);
    }

    function postPic(bytes32 hash, uint newNonce) public {
      require(newNonce == nonce + 1, "New nonce should be 1 more than current nonce.");

      // Do meta transaction stuff
      // User pays for the camera's transaction somehow

      pics.push(hash);
      nonce = newNonce;
    }

    function getLength() public view returns (uint) {
      return pics.length;
    }
}