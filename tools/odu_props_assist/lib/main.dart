import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:odu_props_assist/src/generate_props_assist.dart';

final plugin = OduPropsPlugin();

final class OduPropsPlugin extends Plugin {
  @override
  String get name => 'Odu props assist';

  @override
  void register(PluginRegistry registry) {
    registry.registerAssist(GeneratePropsAssist.new);
  }
}
