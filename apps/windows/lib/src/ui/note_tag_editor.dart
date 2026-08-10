import 'package:flutter/material.dart';

final class NoteTagEditor extends StatefulWidget {
  const NoteTagEditor({required this.tags, required this.onChanged, super.key});

  final List<String> tags;
  final ValueChanged<List<String>> onChanged;

  @override
  State<NoteTagEditor> createState() => _NoteTagEditorState();
}

final class _NoteTagEditorState extends State<NoteTagEditor> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String input) {
    final additions = input
        .split(RegExp('[,，]'))
        .map((tag) => tag.trim().replaceFirst(RegExp(r'^#+'), ''))
        .where((tag) => tag.isNotEmpty);
    final updated = <String>{...widget.tags, ...additions}.toList()..sort();
    _controller.clear();
    if (!_sameTags(updated, widget.tags)) {
      widget.onChanged(updated);
    }
    setState(() {});
  }

  void _remove(String tag) {
    widget.onChanged(
      widget.tags.where((candidate) => candidate != tag).toList(),
    );
  }

  @override
  Widget build(BuildContext context) => Wrap(
    key: const Key('note-tags-editor'),
    spacing: 7,
    runSpacing: 6,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: <Widget>[
      for (final tag in widget.tags)
        InputChip(
          key: ValueKey<String>('note-tag-$tag'),
          label: Text('#$tag'),
          onDeleted: () => _remove(tag),
          visualDensity: VisualDensity.compact,
        ),
      SizedBox(
        width: 180,
        child: TextField(
          key: const Key('note-tag-field'),
          controller: _controller,
          onSubmitted: _submit,
          onChanged: (value) {
            if (value.contains(',') || value.contains('，')) {
              _submit(value);
            }
          },
          textInputAction: TextInputAction.done,
          style: const TextStyle(fontSize: 13),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.tag, size: 17),
            hintText: '添加标签，回车确认',
          ),
        ),
      ),
    ],
  );
}

bool _sameTags(List<String> left, List<String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
