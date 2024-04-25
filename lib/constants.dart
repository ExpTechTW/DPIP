// ignore_for_file: non_constant_identifier_names

class Intensity {
  final String name;
  final String label;
  final int value;

  const Intensity({
    required this.name,
    required this.label,
    required this.value,
  });
}

List<Intensity> IntensityList = const [
  Intensity(name: "１級", label: "1", value: 1),
  Intensity(name: "２級", label: "2", value: 2),
  Intensity(name: "３級", label: "3", value: 3),
  Intensity(name: "４級", label: "4", value: 4),
  Intensity(name: "５弱", label: "5⁻", value: 5),
  Intensity(name: "５強", label: "5⁺", value: 6),
  Intensity(name: "６弱", label: "6⁻", value: 7),
  Intensity(name: "６強", label: "6⁺", value: 8),
  Intensity(name: "７級", label: "7", value: 9),
];
