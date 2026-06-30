import 'package:flutter/material.dart';

/// Ícono y color asociados a la categoría de una meta, usados de forma
/// consistente en la pantalla de Metas y en la tarjeta "Meta principal" del
/// home.
(IconData, Color) goalIconAndColor(String category) {
  switch (category) {
    case 'Casa':
      return (Icons.home, Colors.green);
    case 'Viaje':
      return (Icons.airplanemode_active, Colors.blueAccent);
    case 'Educación':
      return (Icons.school, Colors.purpleAccent);
    case 'Salud':
      return (Icons.favorite, Colors.redAccent);
    case 'Otros':
    default:
      return (Icons.flag, Colors.orangeAccent);
  }
}
