pragma solidity ^0.5.11;

/**
  User Flow:

  1. User goes to the EtherCam webdapp, which has a Login button
    and shows the public timeline.

  2. This generates a login() transaction on the EtherCam contract
    and adds ~$1 balance to the camera (which has its own address)
    so it can post pictures.

    The user is logging into the _camera_ not into the webdapp :).

  3. When user is done taking pics, they log out and get returned
    any balance they didn't use to pay for posting pics.

  4. If the user neglects to logout, after 43 blocks (~10 min) anyone
    else can log in. The neglected balance stays in the camera and
    future users can take free pictures with it or log out with it
 */

contract EtherCam {
    bytes32 public TEST_HASH = sha256("test");

    // 10 min timeout @ 14 sec per block
    uint LOGIN_TIMEOUT_IN_BLOCKS = 43;

    address payable public CAMERA;

    address payable public loggedInUser;
    uint public lastActionBlock;
    bytes32[] public pics;

    constructor(address payable camera) public payable {
      CAMERA = camera;
    }

    modifier canLogin() {
      // If someone is logged in
      if (loggedInUser != address(0)) {
        // Check the user trying to log in isn't already logged in
        require(
          loggedInUser != address(msg.sender),
          "You are already logged in."
        );

        // And only proceed if the previous user has timed out
        require(
          block.number > lastActionBlock + LOGIN_TIMEOUT_IN_BLOCKS,
          "Someone else is currently logged in. Please wait until the previous timeout expires."
        );
      }

      // Otherwise let them log in
      _;
    }

    modifier canLogout() {
      require(loggedInUser != address(0), "No one is logged in");
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
      lastActionBlock = block.number;
      // Load camera up with credits
      // Remainder will be returned upon logout
      CAMERA.transfer(msg.value);
    }

    function logout() public canLogout onlyCamera payable {
      address payable userBeingLoggedOut = loggedInUser;

      loggedInUser = address(0);
      lastActionBlock = uint(0);

      // Camera sends back its balance when it logs out the user
      userBeingLoggedOut.transfer(msg.value);
    }

    function postPic(bytes32 hash) public onlyCamera {
      pics.push(hash);

      // Reset timeout every time pic is posted so user times out
      // 10 minutes after their last pic, not 10 minutes after
      // their first pic
      lastActionBlock = block.number;
    }

    // Anyone can add money to the camera
    function topUpCamera() public payable {
      require(msg.value > 0, "Must send some value when topping up camera");
      // Anyone can put money on the camera, allowing it to take pics
      CAMERA.transfer(msg.value);
    }
}