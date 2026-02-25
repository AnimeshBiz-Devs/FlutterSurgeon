import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/tree_provider.dart';
import 'ui/index.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    BrowserContextMenu.disableContextMenu();
  }
  runApp(const ProviderScope(child: FlutterSurgeonApp()));
}

class FlutterSurgeonApp extends StatelessWidget {
  const FlutterSurgeonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterSurgeon',
      debugShowCheckedModeBanner: false,
      theme: _buildDarkTheme(),
      home: const EditorShell(),
    );
  }

  ThemeData _buildDarkTheme() {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF0F0F1E),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF7C83FF),
        secondary: Color(0xFF4ECDC4),
        surface: Color(0xFF1A1A2E),
        error: Color(0xFFFF6B6B),
      ),
      textTheme: GoogleFonts.interTextTheme(
        base.textTheme,
      ).apply(bodyColor: Colors.white70, displayColor: Colors.white),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF252540),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: Color(0xFF3A3A5C)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: Color(0xFF3A3A5C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: Color(0xFF7C83FF)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF252540),
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: const Color(0xFF1E1E35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
      ),
    );
  }
}

class EditorShell extends ConsumerStatefulWidget {
  const EditorShell({super.key});

  @override
  ConsumerState<EditorShell> createState() => _EditorShellState();
}

class _EditorShellState extends ConsumerState<EditorShell> {
  @override
  Widget build(BuildContext context) {
    final showCode = ref.watch(showCodePanelProvider);

    return Scaffold(
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () =>
              ref.read(widgetTreeProvider.notifier).undo(),
          const SingleActivator(
            LogicalKeyboardKey.keyZ,
            control: true,
            shift: true,
          ): () =>
              ref.read(widgetTreeProvider.notifier).redo(),
        },
        child: Focus(
          autofocus: true,
          child: Column(
            children: [
              // Toolbar
              const AppToolbar(),

              // 3-panel body
              Expanded(
                child: Row(
                  children: [
                    // Screens List (Leftmost)
                    const ScreensPanel(),
                    // Vertical divider
                    const VerticalDivider(
                      color: Color(0xFF2A2A45),
                      width: 1,
                      thickness: 1,
                    ),
                    // Drag target for hierarchy (Middle-left)
                    const LayersPanel(),

                    // Vertical divider
                    const VerticalDivider(
                      color: Color(0xFF2A2A45),
                      width: 1,
                      thickness: 1,
                    ),

                    // Center: Canvas
                    const Expanded(child: CanvasPanel()),

                    // Vertical divider
                    const VerticalDivider(
                      color: Color(0xFF2A2A45),
                      width: 1,
                      thickness: 1,
                    ),

                    // Right: Properties panel
                    const PropertiesPanel(),

                    // Code panel (toggleable, side panel)
                    if (showCode) ...[
                      const VerticalDivider(
                        color: Color(0xFF2A2A45),
                        width: 1,
                        thickness: 1,
                      ),
                      const SizedBox(width: 420, child: CodePanel()),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
