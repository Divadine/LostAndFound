class ApiEndPoints {
  ApiEndPoints._();

  static const String baseUrl = "https://lost-and-found.skyraantech.com/backend/";

  //auth
  static const String generateOtp = 'user/generateOtp';
  static const String verifyOtp = 'user/verifyOtp';
  static const String generateMobileOtp = 'user/generateMobileOtp';
  static const String verifyMobileOtp = 'user/verifyMobileOtp';
  static const String getAddressByPincode = 'user/getAddressByPincode';

  //profile
  static const String updateProfile = 'user/update';
  static const String getUserInfo = 'user/getUserInfo';
  static const String getReasonsDeleteAccount = '/user/getReasonsDeleteAccount';
  static const String deleteAccount = '/user/deleteAccount';
  static const String deleteProfileImage = '/user/deleteProfileImage';

  //category
  static const String getCategory = 'categories/getCategory';

  //sub-category
  static const String getSubCategory = 'subcategories/getSubCategory';
  static const String getDynamicFields = 'subcategories/getDynamicFields';
  static const String getDynamicValues = 'subcategories/getDynamicValues';
  static const String getDynamicNestedValues = 'subcategories/getDynamicNestedValues';


  //image
  static const String createImage = 'Post/createImage';
  static const String createAudio = 'Post/createAudio';
  static const String createVideo = 'Post/createVideo';


  //postForm
  static const String createPostStep1 = 'PostForm/createPostStep1';
  static const String completePostStep2 = 'PostForm/completePostStep2';
  static const String getPost  = 'PostForm/getPost';
  static const String getReasonsDeletePost  = 'PostForm/getReasonsDeletePost';
  static const String deletePost  = 'PostForm/deletePost';
  static const String filterPost  = 'PostForm/filterPost';

  //match
  static const String matchingPost  = 'Match/post';
  static const String viewSingleMatch  = 'Match/viewSingleMatch';

  //handover
  static const String getHandoverOwnerList  = 'handover/getHandoverOwnerList';

  static const String generateHandoverOtp = 'handover/generateOtp';
  static const String verifyHandoverOtp = 'handover/verifyhandoverotp';
  static const String createHandover = 'handover/createHandover';


  //nearby policestation
  static const String searchLocation = 'handover/searchLocation';
  static const String nearbyPoliceStations = 'handover/nearbyPoliceStations';


  //color
  static const String getColors = 'admin/getColors';

  //enquiry
  static const createEnquiry = 'enquiry/createEnquiry';
  static const viewEnquiry = 'enquiry/viewEnquiry';


  //logout
  static const String logout = '/user/Logout';


  //report
  static const String createReport = 'handover/createReport';





}