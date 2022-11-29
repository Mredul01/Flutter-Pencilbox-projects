import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../provider/weather_provider.dart';
import '../utils/constrant.dart';
import '../utils/helper_function.dart';
import '../utils/location_service.dart';
import '../utils/text_style.dart';

class WeatherPage extends StatefulWidget {
  static const String routeName = '/';
  const WeatherPage({Key? key}) : super(key: key);

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> with WidgetsBindingObserver {
  late WeatherProvider provider;
  bool isFirst = true;
  Timer? timer;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        print('on resumed');
        break;
      case AppLifecycleState.inactive:
        // TODO: Handle this case.
        break;
      case AppLifecycleState.paused:
        // TODO: Handle this case.
        break;
      case AppLifecycleState.detached:
        // TODO: Handle this case.
        break;
    }
  }

  @override
  void didChangeDependencies() {
    if (isFirst) {
      provider = Provider.of<WeatherProvider>(context);
      _getData();
      isFirst = false;
    }
    super.didChangeDependencies();
  }

  _startTimer() {
    timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      // print('timer started');
      final isOn = await Geolocator.isLocationServiceEnabled();
      if (isOn) {
        _startTimer();
        _getData();
      }
    });
  }

  stopTimer() {
    if (timer != null) {
      timer!.cancel();
    }
  }

  _getData() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      showMsgWithAction(
        context: context,
        msg: 'Please turn on Location',
        callback: () async {
          _startTimer();
          final status = await Geolocator.openLocationSettings();
          print('status: $status');
        },
      );
    }

    try {
      Position position = await determinePosition();
      provider.setNewLocation(position.latitude, position.longitude);
      provider.setTempUnit(await provider.getPreferenceTempUnitValue());
      provider.getWeatherData();
    } catch (error) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Weather'),
        actions: [
          IconButton(
            onPressed: () {
              _getData();
            },
            icon: const Icon(Icons.my_location),
          ),
          IconButton(
            onPressed: () async {
              try {
                final result = await showSearch(
                    context: context, delegate: _CitySearchDelegate());
                if (result != null && result.isNotEmpty) {
                  print(result);
                  provider.convertCityToLatLong(
                      result: result,
                      onErr: (err) {
                        showMsg(context, err);
                      });
                }
              } catch (error) {
                rethrow;
              }
            },
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: provider.hasDataLocated
          ? Stack(
              // padding: const EdgeInsets.all(8),
              children: [
                Image.asset('images/bg.gif',height: double.maxFinite,width: double.maxFinite,fit: BoxFit.cover,),

                SizedBox(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  child: _currentWeatherSection(),
                ),
                Positioned(bottom: 10, child: _forecastWeatherSection()),
              ],
            )
          : const Center(
              child: Text(
                'Please wait...',
                style: txtNormal16,
              ),
            ),
    );
  }

  Widget _currentWeatherSection() {
    final response = provider.currentResponseModel;
    return Column(
      // mainAxisSize: MainAxisSize.,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(activeThumbImage: const AssetImage('images/f.jpg'),
            inactiveThumbImage:const AssetImage('images/c.jpg') ,
            activeColor: Colors.transparent,
            controlAffinity: ListTileControlAffinity.leading,
            value: provider.isFahrenheit,
            onChanged: (value) async {
              provider.setTempUnit(value);
              await provider.setTempUnitPreferenceValue(value);
              provider.getWeatherData();
            }),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  getFormattedDateTime(response!.dt!, 'MMM dd, yyyy'),
                  style: txtDateHeader18,
                ),
                Text(
                  '${response.name},${response.sys!.country}',
                  style: txtAddress24,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              //mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(
                  '$iconPrefix${response.weather![0].icon}$iconSuffix',
                  fit: BoxFit.cover,
                ),
                Text(
                  '${response.main!.temp!.round()}$degree${provider.unitSymbol}',
                  style: txtTempBig80,
                )
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Column(
              children: [
                Wrap(
                  children: [
                    Text(
                      'Feels like ${response.main!.feelsLike!.round()}$degree${provider.unitSymbol}',
                      style: txtNormal16,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      '${response.weather![0].main}, ${response.weather![0].description}',
                      style: txtNormal16,
                    )
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                Wrap(
                  children: [
                    Text(
                      'Humidity ${response.main!.humidity}%',
                      style: txtNormal16White54,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      'Pressure ${response.main!.pressure}hPa',
                      style: txtNormal16White54,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                Wrap(
                  children: [


                    Column(
                      children: [
                        const CircleAvatar(
                          backgroundImage: AssetImage('images/sunrise.png',),
                        ),
                        Text(
                          'Sunrise ${getFormattedDateTime(response.sys!.sunrise!, 'hh:mm a')}',
                          style: txtNormal16,
                        ),
                      ],
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Column(
                      children: [
                        const CircleAvatar(
                          backgroundImage: AssetImage('images/sunset.png',),
                        ),
                        Text(
                          'Sunset ${getFormattedDateTime(response.sys!.sunset!, 'hh:mm a')}',
                          style: txtNormal16,
                        ),
                      ],
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _forecastWeatherSection() {
    final forecastList = provider.forecastResponseModel!.list;
    return SizedBox(
      height: 150,
      width: MediaQuery.of(context).size.width,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: forecastList!.length,
        itemBuilder: (context, index) => Card(
          elevation: 5,
          color: Colors.white70,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  getFormattedDateTime(forecastList[index].dt!, 'MMM,hh:mm a'),
                  //style: TextStyle(color: Colors.white),
                ),
                Column(
                  children: [
                    Image.network(
                      '$iconPrefix${forecastList[index].weather![0].icon}$iconSuffix',
                      height: 30,
                      width: 30,
                      fit: BoxFit.cover,
                    ),
                    Text(
                        '${forecastList[index].main!.temp!.round()}$degree${provider.unitSymbol}'),
                  ],
                ),
                Text('${forecastList[index].main!.humidity}%'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CitySearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = '';
        },
        icon: const Icon(Icons.cancel),
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    IconButton(
      onPressed: () {
        close(context, '');
      },
      icon: const Icon(Icons.arrow_back),
    );
    return null;
  }

  @override
  Widget buildResults(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.search),
      title: Text(query),
      onTap: () {
        close(context, query);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final filteredList = query.isEmpty
        ? cities
        : cities
            .where((city) => city.toLowerCase().startsWith(query.toLowerCase()))
            .toList();

    return ListView.builder(
      itemCount: filteredList.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(filteredList[index]),
        onTap: () {
          query = filteredList[index];
          close(context, query);
        },
      ),
    );
  }
}
