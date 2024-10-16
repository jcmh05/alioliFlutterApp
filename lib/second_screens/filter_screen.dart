import 'package:alioli/components/components.dart';
import 'package:checkmark/checkmark.dart';
import 'package:flutter/material.dart';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

class FiltersScreen extends StatefulWidget {
  final Function applyFilters;
  String _orderBy;
  bool _isVegetarian;
  bool _isVegan;
  bool _hasVideo;
  int? _minMinutes;
  int? _maxMinutes;

  FiltersScreen(this._orderBy, this._isVegetarian, this._isVegan, this._hasVideo, this.applyFilters, {int? minMinutes, int? maxMinutes}) {
    _minMinutes = minMinutes;
    _maxMinutes = maxMinutes;
  }

  @override
  _FiltersScreenState createState() => _FiltersScreenState(_orderBy, _isVegetarian, _isVegan, _hasVideo, minMinutes: _minMinutes, maxMinutes: _maxMinutes);
}

class _FiltersScreenState extends State<FiltersScreen> {
  String _orderBy = 'createdAt';
  double _currentSliderValue = 4;
  int _selection = 0;
  bool _hasVideo = false;
  int? _minMinutes;
  int? _maxMinutes;

  _FiltersScreenState(String orderBy, bool _isVegetarian, bool _isVegan, bool hasVideo, {int? minMinutes, int? maxMinutes}) {
    _orderBy = orderBy;
    this._selection = _isVegetarian ? 1 : _isVegan ? 2 : 0;
    this._hasVideo = hasVideo;
    _minMinutes = minMinutes;
    _maxMinutes = maxMinutes;
    switch (maxMinutes) {
        case 15:
          _currentSliderValue = 0;
          break;
        case 30:
          _currentSliderValue = 1;
          break;
        case 45:
          _currentSliderValue = 2;
          break;
        case 60:
          _currentSliderValue = 3;
          break;
        default:
          _currentSliderValue = 4;
      }
  }

  Widget orderWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: <Widget>[
          RadioListTile<String>(
            title: Row(
              children: <Widget>[
                Icon(Icons.history),
                SizedBox(width: 10,),
                Text("Más recientes"),
              ],
            ),
            value: "createdAt",
            groupValue: _orderBy,
            onChanged: (String? value) {
              setState(() {
                _orderBy = value ?? _orderBy;
              });
            },
            controlAffinity: ListTileControlAffinity.trailing,
            visualDensity: VisualDensity.compact,
          ),
          Divider(thickness: 1.0),
          RadioListTile<String>(
            title: Row(
              children: <Widget>[
                Icon(Icons.favorite_border_outlined),
                SizedBox(width: 10,),
                Text("Más valoradas"),
              ],
            ),
            value: "likesCount",
            groupValue: _orderBy,
            onChanged: (String? value) {
              setState(() {
                _orderBy = value ?? _orderBy;
              });
            },
            controlAffinity: ListTileControlAffinity.trailing,
            visualDensity: VisualDensity.compact,
          ),
          Divider(thickness: 1.0),
          RadioListTile<String>(
            title: Row(
              children: <Widget>[
                //Icono de un rayo
                Icon(Icons.hourglass_empty_rounded),
                SizedBox(width: 10,),
                Text("Tiempo"),
              ],
            ),
            value: "minutes",
            groupValue: _orderBy,
            onChanged: (String? value) {
              setState(() {
                _orderBy = value ?? _orderBy;
              });
            },
            controlAffinity: ListTileControlAffinity.trailing,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  String getLabel(double value) {
    switch (value.round()) {
      case 0:
        return '15 min';
      case 1:
        return '30 min';
      case 2:
        return '45 min';
      case 3:
        return '60 min';
      case 4:
        return 'Indefinido';
      default:
        return 'Valor no válido';
    }
  }

  Widget sliderTime() {
    return SfSlider(
      min: 0.0,
      max: 4.0,
      value: _currentSliderValue,
      interval: 1,
      stepSize: 1.0,
      showLabels: true,
      showTicks: true,
      activeColor: AppTheme.pantry,
      inactiveColor: Colors.grey,
      labelFormatterCallback: (actualValue, formattedText) {
        return getLabel(actualValue);
      },
      onChanged: (dynamic newValue) {
        setState(() {
          _currentSliderValue = newValue;
        });
      },
    );
  }

  Widget dietWidget() {
    return AnimatedToggleSwitch<int>.size(
      current: _selection,
      values: [0, 1, 2],
      onChanged: (value) => setState(() {
        _selection = value;
      }),
      iconBuilder: (index) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if( index!=0)
            Padding(
              padding: const EdgeInsets.only(right: 3.0),
              child: Icon(
                index == 0 ? null : index == 1 ? AppTheme.categoryIcons['vegetarian'] : AppTheme.categoryIcons['vegan'] ,
                color: index==_selection
                    ? Colors.black
                    : (MediaQuery.of(context).platformBrightness == Brightness.dark ? Colors.white : Colors.black),
                size: 12,
              ),
            ),
          Text(
              index == 0 ? 'Nada' : index == 1 ? 'Vegetariana' : 'Vegana',
              style: TextStyle(
                color: index==_selection
                    ? Colors.black
                    : (MediaQuery.of(context).platformBrightness == Brightness.dark ? Colors.white : Colors.black),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              )
          ),
        ],
      ),
      styleBuilder: (value) {
        switch (value) {
          case 0:
            return ToggleStyle(
              indicatorColor: Colors.grey,
            );
          case 1:
            return ToggleStyle(
              indicatorColor: AppTheme.categoryColors['vegetarian'],
            );
          case 2:
            return ToggleStyle(
              indicatorColor: AppTheme.categoryColors['vegan'],
            );
          default:
            return ToggleStyle(
              indicatorColor: Colors.grey,
            );
        }
      },
      indicatorSize: const Size(300, 40),
      borderWidth: 1.0,
      animationDuration: Duration(milliseconds: 150),
      animationCurve: Curves.easeInOut,
      iconOpacity: 0.8,
      height: 40,
    );
  }

  Widget videoWidget() {
    return InkWell(
      onTap: () {
        setState(() {
          _hasVideo = !_hasVideo;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(width: 5,),
            SizedBox(
              height: 20,
              width: 20,
              child: CheckMark(
                active: _hasVideo,
                curve: Curves.decelerate,
                duration: const Duration(milliseconds: 500),
              ),
            ),
            SizedBox(width: 10,),
            Text(
                "Contiene vídeo",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                )
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Filtros'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Ordenar',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  orderWidget(),
                  SizedBox(height: 30,),
                  Text(
                    'Tiempo de preparación',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  sliderTime(),
                  SizedBox(height: 30,),
                  Text(
                    'Dieta',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  SizedBox(height: 10,),
                  dietWidget(),
                  SizedBox(height: 30,),
                  Text(
                    'Vídeo',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  videoWidget(),

                  SizedBox(height: 150,),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Rounded3dButton('Aplicar filtros', AppTheme.pantry, AppTheme.pantry_second, icon: Icons.add, height: 60.0,
                          () {
                        bool _isVegetarian;
                        bool _isVegan;
                        if ( _selection == 0 ) {
                          _isVegetarian = false;
                          _isVegan = false;
                        } else if ( _selection == 2 ) {
                          _isVegetarian = true;
                          _isVegan = false;
                        } else {
                          _isVegetarian = false;
                          _isVegan = true;
                        }
                        int? maxMinutes;
                        switch (_currentSliderValue.round()) {
                          case 0:
                            maxMinutes = 15;
                            break;
                          case 1:
                            maxMinutes = 30;
                            break;
                          case 2:
                            maxMinutes = 45;
                            break;
                          case 3:
                            maxMinutes = 60;
                            break;
                          case 4:
                            maxMinutes = null;
                            break;
                        }
                        widget.applyFilters(_orderBy, maxMinutes, _isVegetarian, _isVegan, _hasVideo);
                        Navigator.pop(context);
                      }
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}