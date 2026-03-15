import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/models/tag.dart';
import '../core/providers/tag_provider.dart';

class TagPicker extends StatefulWidget {
  final List<String> initialTags;
  final ValueChanged<List<String>> onTagsChanged;

  const TagPicker({
    super.key,
    required this.initialTags,
    required this.onTagsChanged,
  });

  @override
  State<TagPicker> createState() => _TagPickerState();
}

class _TagPickerState extends State<TagPicker> {
  late List<String> _selectedTags;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTags = List.from(widget.initialTags);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleTag(String id) {
    setState(() {
      if (_selectedTags.contains(id)) {
        _selectedTags.remove(id);
      } else {
        _selectedTags.add(id);
      }
    });
    widget.onTagsChanged(_selectedTags);
  }

  void _createTag(BuildContext context) {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    final p = Provider.of<TagProvider>(context, listen: false);
    final tag = Tag(
      id: p.generateId(),
      name: name,
      color: Colors.orange.toARGB32(),
    );
    p.addTag(tag);
    _controller.clear();
    _toggleTag(tag.id);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TagProvider>(
      builder: (context, tagProvider, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tags',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tagProvider.tags.map((tag) {
                final isSelected = _selectedTags.contains(tag.id);
                return FilterChip(
                  label: Text('#${tag.name}'),
                  selected: isSelected,
                  onSelected: (_) => _toggleTag(tag.id),
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  selectedColor: Color(tag.color).withValues(alpha: 0.3),
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Nouveau tag...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _createTag(context),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blueAccent),
                  onPressed: () => _createTag(context),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
