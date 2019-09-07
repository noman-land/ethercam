pragma solidity ^0.5.11;

/**
  User Flow:

  1. User goes to the EthCam webdapp, which has a Login button
    and shows the public timeline.

  2. This generates a login() transaction on the EthCam contract
    and adds ~$1 balance to the camera (which has its own address)
    so it can post pictures.

    The user is logging into the _camera_ not into the webdapp :).

  3. When user is done taking pics, they log out and get returned
    any balance they didn't use to pay for posting pics.

  4. If the user neglects to logout, after 21 blocks (~5 min) anyone
    else can log in. The neglected balance _gets returned to its
    rightful owner_.
 */

contract EthCam {
    // 5 min timeout @ 14 sec per block
    uint LOGIN_TIMEOUT_IN_BLOCKS = 21;

    address payable public CAMERA;

    address payable public loggedInUser;
    uint public loggedInBlock;
    uint public nonce;
    bytes32[] public pics;

    constructor(address payable camera) public {
      CAMERA = camera;
    }

    modifier canLogin() {
      if (loggedInUser != address(0)) {
        require(
          loggedInUser != address(msg.sender),
          "You are already logged in."
        );

        require(
          block.number > loggedInBlock + LOGIN_TIMEOUT_IN_BLOCKS,
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

    function sendBalanceTo(address payable user) internal {
      user.transfer(address(this).balance);
    }

    function topUpCamera() public payable {
      CAMERA.transfer(msg.value);
    }
}