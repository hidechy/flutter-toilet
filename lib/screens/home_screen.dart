// ignore_for_file: inference_failure_on_collection_literal

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_place/google_place.dart';
import 'package:url_launcher/url_launcher.dart';

import '../model/toilet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String apiKey = 'AIzaSyD9PkTM1Pur3YzmO-v4VzS0r8ZZ0jRJTIU';

  Toilet? toilet;
  Uri? mapUri;
  bool? isExist;

  ///
  @override
  void initState() {
    super.initState();

    getPosition();
  }

  ///
  Future<void> getPosition() async {
    final currentPosition = await _determinePosition();

    final googlePlace = GooglePlace(apiKey);

    final response = await googlePlace.search.getNearBySearch(
      Location(lat: currentPosition.latitude, lng: currentPosition.longitude),
      1000,
      keyword: '郵便局',
      rankby: RankBy.Distance,
      language: 'ja',
    );

    final results = response?.results;

    //---------------------------//s
    // 取得できたかフラグの作成

    final isExist = results?.isNotEmpty ?? false;

    setState(() {
      this.isExist = isExist;
    });

    if (isExist == false) {
      return;
    }
    //---------------------------//e

    final firstResult = results?.first;

    if (firstResult != null && mounted) {
      final distination = firstResult.geometry?.location;

      //---------------------------//s
      // GoogleMapのURLの作成

      final urlStringVars = [];
      if (Platform.isAndroid) {
        urlStringVars
          ..add('https://www.google.co.jp/maps/dir/')
          ..add('${currentPosition.latitude},${currentPosition.longitude}/')
          ..add('${distination?.lat},${distination?.lng}/');
      } else if (Platform.isIOS) {
        urlStringVars
          ..add('comgooglemaps://')
          ..add(
              '?saddr=${currentPosition.latitude},${currentPosition.longitude}')
          ..add('&daddr=${distination?.lat},${distination?.lng}')
          ..add('&directionsmode=walking');
      }
      mapUri = Uri.parse(urlStringVars.join());
      //---------------------------//e

      setState(() {
        final photoReference = firstResult.photos?.first.photoReference;

        final photoVars = [
          'https://maps.googleapis.com',
          '?maxWidth=2000',
          '&photo_reference=$photoReference',
          '&key=$apiKey'
        ];

        toilet = Toilet(firstResult.name, photoVars.join(), distination);
      });
    }
  }

  ///
  @override
  Widget build(BuildContext context) {
    if (isExist == false) {
      return const Scaffold(
        body: Center(child: Text('近くにトイレがありません。')),
      );
    }

    if (toilet == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('近くのトイレ'),
      ),
      body: Column(
        children: [
          Image.network(
            toilet!.photo!,
            errorBuilder: (c, o, s) {
              return Image.asset('assets/images/no_image.png');
            },
          ),
          Text(toilet!.name!),
          ElevatedButton(
            onPressed: () async {
              if (mapUri != null) {
                await launchUrl(mapUri!);
              }
            },
            child: const Text('マップを開く'),
          ),
        ],
      ),
    );
  }

  ///
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return Geolocator.getCurrentPosition();
  }
}
