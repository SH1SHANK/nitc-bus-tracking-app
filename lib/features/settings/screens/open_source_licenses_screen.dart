import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/tracklet_fonts.dart';

/// Fullscreen Open Source Licenses browser for Tracklet.
///
/// Discovers licenses dynamically from Flutter's native [LicenseRegistry]
/// with search filtering and collapsible package cards.
class OpenSourceLicensesScreen extends StatefulWidget {
  const OpenSourceLicensesScreen({super.key});

  @override
  State<OpenSourceLicensesScreen> createState() =>
      _OpenSourceLicensesScreenState();
}

class _PackageLicense {
  _PackageLicense({required this.packageName, required this.paragraphs});

  final String packageName;
  final List<String> paragraphs;
}

class _OpenSourceLicensesScreenState extends State<OpenSourceLicensesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<_PackageLicense> _allLicenses = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadLicenses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLicenses() async {
    final Map<String, List<String>> packageMap = {};

    try {
      await for (final entry in LicenseRegistry.licenses) {
        final text = entry.paragraphs.map((p) => p.text).join('\n\n');
        for (final package in entry.packages) {
          packageMap.putIfAbsent(package, () => []).add(text);
        }
      }
    } catch (_) {
      // Fallback to core libraries if registry stream encounters an error
      packageMap['tracklet'] = [
        'Copyright (c) 2026 Shashank Mergu & NITC Tracklet Contributors\nReleased under MIT License.',
      ];
    }

    final list =
        packageMap.entries
            .map(
              (e) => _PackageLicense(packageName: e.key, paragraphs: e.value),
            )
            .toList()
          ..sort((a, b) => a.packageName.compareTo(b.packageName));

    if (mounted) {
      setState(() {
        _allLicenses = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = TrackletColors.isDark(context);
    final filtered =
        _searchQuery.isEmpty
            ? _allLicenses
            : _allLicenses
                .where(
                  (pkg) => pkg.packageName.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ),
                )
                .toList();

    return Scaffold(
      backgroundColor: TrackletColors.adaptiveBackground(context),
      appBar: AppBar(
        backgroundColor: TrackletColors.adaptiveBackground(context),
        foregroundColor: TrackletColors.adaptiveTextPrimary(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
        title: Text(
          'Open Source Licenses',
          style: TrackletFonts.outfit(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: TrackletColors.adaptiveTextPrimary(context),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TrackletSpacing.screenMargin,
              vertical: TrackletSpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: TrackletFonts.outfit(
                fontSize: 14,
                color: TrackletColors.adaptiveTextPrimary(context),
              ),
              decoration: InputDecoration(
                hintText: 'Search packages (e.g. flutter, riverpod)...',
                hintStyle: TrackletFonts.outfit(
                  fontSize: 13,
                  color: TrackletColors.adaptiveTextSecondary(context),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: TrackletColors.adaptiveTextSecondary(context),
                ),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                        : null,
                filled: true,
                fillColor: TrackletColors.adaptiveSurface(context),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TrackletRadii.md),
                  borderSide: BorderSide(
                    color: TrackletColors.adaptiveBorder(context),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TrackletRadii.md),
                  borderSide: const BorderSide(
                    color: TrackletColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // License list
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: TrackletColors.primary,
                        strokeWidth: 2.5,
                      ),
                    )
                    : filtered.isEmpty
                    ? Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'No licenses found.'
                            : 'No matching packages for "$_searchQuery"',
                        style: TrackletFonts.outfit(
                          fontSize: 14,
                          color: TrackletColors.adaptiveTextSecondary(context),
                        ),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TrackletSpacing.screenMargin,
                        vertical: TrackletSpacing.sm,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final pkg = filtered[index];
                        return _buildLicenseCard(context, pkg, isDark);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseCard(
    BuildContext context,
    _PackageLicense pkg,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: TrackletSpacing.md),
      decoration: BoxDecoration(
        color: TrackletColors.adaptiveSurface(context),
        borderRadius: BorderRadius.circular(TrackletRadii.card),
        border: Border.all(color: TrackletColors.adaptiveBorder(context)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(
            horizontal: TrackletSpacing.md,
            vertical: 4,
          ),
          leading: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: TrackletColors.primary.withValues(
                alpha: isDark ? 0.2 : 0.08,
              ),
              borderRadius: BorderRadius.circular(TrackletRadii.xs),
            ),
            child: const Icon(
              Icons.extension_outlined,
              size: 20,
              color: TrackletColors.primary,
            ),
          ),
          title: Text(
            pkg.packageName,
            style: TrackletFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: TrackletColors.adaptiveTextPrimary(context),
            ),
          ),
          subtitle: Text(
            '${pkg.paragraphs.length} license ${pkg.paragraphs.length == 1 ? "clause" : "clauses"}',
            style: TrackletFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: TrackletColors.adaptiveTextSecondary(context),
            ),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(TrackletSpacing.md),
              margin: const EdgeInsets.fromLTRB(
                TrackletSpacing.md,
                0,
                TrackletSpacing.md,
                TrackletSpacing.md,
              ),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? TrackletColors.darkSurfaceElevated
                        : TrackletColors.background,
                borderRadius: BorderRadius.circular(TrackletRadii.xs),
                border: Border.all(
                  color:
                      isDark
                          ? TrackletColors.darkBorder
                          : TrackletColors.border,
                ),
              ),
              child: SelectableText(
                pkg.paragraphs.join('\n\n---\n\n'),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11.5,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
