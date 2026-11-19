import 'package:tehillah/core/models/keeper_profile.dart';
import 'package:tehillah/core/models/opponent_def.dart';
import 'package:tehillah/core/models/shot_outcome.dart';
import 'package:tehillah/core/models/stage_def.dart';

/// The twelve Journey stages, four rounds each (48 matches). Every opponent,
/// team and place is fictional. Difficulty numbers are tuning starting points.
abstract final class StageCatalog {
  static const int roundsPerStage = 4;

  static const List<String> _nameKeys = <String>[
    'stageGarden',
    'stageArarat',
    'stageRedSeaShore',
    'stageSinai',
    'stageJerichoPlain',
    'stageValleyOfElah',
    'stageBabylonGates',
    'stageGalilee',
    'stageDamascusRoad',
    'stageAntioch',
    'stagePatmosShore',
    'stageNewJerusalem',
  ];

  static const List<String> _teams = <String>[
    'Eden Rovers',
    'Ararat Athletic',
    'Shoreline Wanderers',
    'Sinai Rangers',
    'Plains United',
    'Elah Valley FC',
    'Gatekeepers Town',
    'Galilee Mariners',
    'Roadside Harriers',
    'Antioch City',
    'Patmos Isle FC',
    'Lamplight City',
  ];

  static const List<double> _difficulty = <double>[
    0.10, 0.18, 0.26, 0.34, 0.42, 0.52, 0.60, 0.68, 0.76, 0.82, 0.88, 0.95,
  ];

  /// Crosswind per stage; Galilee is the windy one.
  static const List<double> _wind = <double>[
    0, 0, 0.10, 0, 0, 0, -0.15, 0.60, 0, -0.20, 0.30, 0,
  ];

  /// How well the keepers learn the player's habits; starts at Damascus Road.
  static const List<double> _habitReading = <double>[
    0, 0, 0, 0, 0, 0, 0, 0, 0.40, 0.50, 0.60, 0.80,
  ];

  /// Boss stages: Valley of Elah and New Jerusalem.
  static const Set<int> _bossStages = <int>{6, 12};

  static const List<String> _firstNames = <String>[
    'Tobin', 'Elias', 'Marek', 'Ansel', 'Joaquin', 'Rafe', 'Bram', 'Lucan',
    'Dario', 'Soren', 'Idris', 'Kaito', 'Nils', 'Oren', 'Teodor', 'Yusuf',
  ];

  static const List<String> _lastNames = <String>[
    'Ashgrove', 'Brightwell', 'Cedarfield', 'Dunmere', 'Eastvale',
    'Fernhollow', 'Greymoor', 'Hollowby', 'Ironwood', 'Juniper', 'Kestrel',
    'Larkspur', 'Marlowe', 'Northcote', 'Oakhaven', 'Pennywick',
  ];

  /// Starting weights for the six dives; each opponent gets a rotation of it.
  static const List<double> _tendencyPattern = <double>[
    0.22, 0.12, 0.16, 0.10, 0.24, 0.16,
  ];

  static final List<StageDef> stages = List<StageDef>.unmodifiable(
    <StageDef>[for (int i = 0; i < _nameKeys.length; i++) _buildStage(i)],
  );

  static StageDef? byId(int id) {
    for (final StageDef stage in stages) {
      if (stage.id == id) {
        return stage;
      }
    }
    return null;
  }

  static StageDef _buildStage(int index) {
    final int id = index + 1;
    return StageDef(
      id: id,
      nameKey: _nameKeys[index],
      difficulty: _difficulty[index],
      wind: _wind[index],
      isBoss: _bossStages.contains(id),
      opponents: <OpponentDef>[
        for (int round = 1; round <= roundsPerStage; round++)
          _buildOpponent(index, round),
      ],
    );
  }

  static OpponentDef _buildOpponent(int stageIndex, int round) {
    final int n = stageIndex * roundsPerStage + (round - 1);
    final double strength =
        (_difficulty[stageIndex] + 0.01 * (round - 1)).clamp(0.0, 1.0);
    final List<double> pattern = <double>[
      for (int k = 0; k < KeeperDive.values.length; k++)
        _tendencyPattern[(k + n) % KeeperDive.values.length],
    ];
    final double total = pattern.fold(0.0, (double a, double b) => a + b);
    final String stageLabel = (stageIndex + 1).toString().padLeft(2, '0');
    return OpponentDef(
      id: 's${stageLabel}r$round',
      name: '${_firstNames[n % 16]} ${_lastNames[(n * 7 + (n ~/ 16) * 3) % 16]}',
      team: _teams[stageIndex],
      keeper: KeeperProfile(
        reaction: 0.30 + 0.60 * strength,
        reach: 0.35 + 0.55 * strength,
        habitReading: _habitReading[stageIndex],
        tendency: <KeeperDive, double>{
          for (int k = 0; k < KeeperDive.values.length; k++)
            KeeperDive.values[k]: pattern[k] / total,
        },
      ),
    );
  }
}
