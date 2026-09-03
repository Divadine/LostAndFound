import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/app_text_field.dart';
import 'package:lost_and_found/utils/app_colors.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  TextEditingController searchController = TextEditingController();
  LatLng? selectedLocation;
  GoogleMapController? mapController;


  CameraPosition initialPosition = CameraPosition(target: LatLng(11.040366232580462, 76.99749305902779),zoom: 12);

  Future<void> searchedLocation(String loc) async{

    List<Location> locations = await locationFromAddress(loc);

    if(locations.isNotEmpty){
      final  location = locations.first;
      final searchLocation = LatLng(location.latitude, location.longitude);

      setState(() {
        selectedLocation = searchLocation;
      });

      mapController?.animateCamera(CameraUpdate.newLatLngZoom(searchLocation, 15));
    }


  }
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,backgroundColor: AppColors.primaryColor,
      ),

      body: Stack(
        children: [
          GoogleMap(
              initialCameraPosition: initialPosition,

              onMapCreated: (controller) {
                mapController = controller;
              },

              onTap: (LatLng location){
                setState(() {
                  selectedLocation =location;
                });
              },
              markers:selectedLocation == null ? {} : {
                Marker(
                  markerId: MarkerId('location'),
                  position: selectedLocation!,

                ),
              }


          ),

          Positioned(
            bottom: 20,
            left: 0,right: 0,
            child: Center(
              child:
              AppButton(title: 'Confirm Location', onTap: (){
                setState(() {

                });
              })
            ),
          ),



          //search box
          Padding(
            padding: const EdgeInsets.all(60),
            child: TextField(
              inputFormatters: [NoLeadingSpaceFormatter()],
              onChanged: (value){
                searchedLocation(value);
              },

              controller: searchController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search,size: 30,color: AppColors.primaryColor ),
                border: OutlineInputBorder(),
                hintText:  'Search here...',
                //hintStyle: AppTextStyle(fontFamily: AppPreference.getFont(),fontSize: 20,fontWeight: FontWeight.bold,color: Colors.black),
                enabledBorder: OutlineInputBorder(

                ),


              ),


            ),
          ),
        ],
      ),
    );
  }
}