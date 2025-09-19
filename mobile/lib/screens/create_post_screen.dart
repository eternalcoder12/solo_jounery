import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime _visitedAt = DateTime.now();
  TimeOfDay _visitedTime = TimeOfDay.now();
  String _mediaType = 'image';
  final _mediaUrlController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _deviceController = TextEditingController(text: 'iPhone 14 Pro');
  final _signatureController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('分享旅程', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: '标题'),
                  validator: (value) => value == null || value.isEmpty ? '请输入标题' : null,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: '描述'),
                  maxLines: 3,
                  validator: (value) => value == null || value.isEmpty ? '请输入描述' : null,
                ),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: '地点'),
                  validator: (value) => value == null || value.isEmpty ? '请输入地点' : null,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('到访日期：${_visitedAt.toLocal().toString().split(' ').first}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _visitedAt,
                      firstDate: DateTime(2015),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _visitedAt = DateTime(date.year, date.month, date.day, _visitedTime.hour, _visitedTime.minute));
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('具体时间：${_visitedTime.format(context)}'),
                  trailing: const Icon(Icons.schedule),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _visitedTime,
                    );
                    if (time != null) {
                      setState(() {
                        _visitedTime = time;
                        _visitedAt = DateTime(_visitedAt.year, _visitedAt.month, _visitedAt.day, time.hour, time.minute);
                      });
                    }
                  },
                ),
                const Divider(height: 32),
                Text('媒体信息', style: Theme.of(context).textTheme.titleMedium),
                DropdownButtonFormField<String>(
                  value: _mediaType,
                  items: const [
                    DropdownMenuItem(value: 'image', child: Text('图片')),
                    DropdownMenuItem(value: 'video', child: Text('视频')),
                  ],
                  onChanged: (value) => setState(() => _mediaType = value ?? 'image'),
                ),
                TextFormField(
                  controller: _mediaUrlController,
                  decoration: const InputDecoration(labelText: '媒体URL'),
                  validator: (value) => value != null && value.startsWith('http') ? null : '请输入有效链接',
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latitudeController,
                        decoration: const InputDecoration(labelText: '纬度'),
                        keyboardType: TextInputType.number,
                        validator: (value) => value != null && value.isNotEmpty ? null : '请填写纬度',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _longitudeController,
                        decoration: const InputDecoration(labelText: '经度'),
                        keyboardType: TextInputType.number,
                        validator: (value) => value != null && value.isNotEmpty ? null : '请填写经度',
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  controller: _deviceController,
                  decoration: const InputDecoration(labelText: '拍摄设备'),
                ),
                TextFormField(
                  controller: _signatureController,
                  decoration: const InputDecoration(labelText: '原始文件签名 (可选)'),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _submit(context),
                  icon: const Icon(Icons.send),
                  label: const Text('发布'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _mediaUrlController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _deviceController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final latitude = double.tryParse(_latitudeController.text);
    final longitude = double.tryParse(_longitudeController.text);

    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写有效的经纬度信息')),
      );
      return;
    }

    final metadata = jsonEncode({
      'captured_at': DateTime(_visitedAt.year, _visitedAt.month, _visitedAt.day, _visitedTime.hour, _visitedTime.minute)
          .toUtc()
          .toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'device': _deviceController.text,
      'signature': _signatureController.text,
    });

    await context.read<AppState>().createTrip(
          title: _titleController.text,
          description: _descriptionController.text,
          location: _locationController.text,
          visitedAt: _visitedAt,
          media: [
            {
              'type': _mediaType,
              'url': _mediaUrlController.text,
              'metadata_raw': metadata,
            }
          ],
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('旅程已发布，积分已更新！')),
      );
      _titleController.clear();
      _descriptionController.clear();
      _locationController.clear();
      _mediaUrlController.clear();
      _latitudeController.clear();
      _longitudeController.clear();
      _signatureController.clear();
      _deviceController.text = 'iPhone 14 Pro';
      _formKey.currentState!.reset();
    }
  }
}
