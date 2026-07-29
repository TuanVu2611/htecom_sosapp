// ignore_for_file: file_names

import 'dart:io';
import 'dart:typed_data';

import 'package:hcmu_sos/Entity/PendingTicketEntity.dart';
import 'package:hcmu_sos/Utils/StorageManager.dart';
import 'package:path_provider/path_provider.dart';

class PendingTicketAttachmentDraft {
  const PendingTicketAttachmentDraft({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;
}

class PendingTicketCreateInput {
  const PendingTicketCreateInput({
    required this.incidentTypeId,
    required this.title,
    required this.description,
    required this.priority,
    required this.locationText,
    required this.latitude,
    required this.longitude,
    required this.attachments,
  });

  final int incidentTypeId;
  final String title;
  final String description;
  final String priority;
  final String locationText;
  final double latitude;
  final double longitude;
  final List<PendingTicketAttachmentDraft> attachments;
}

class PendingTicketRepository {
  static const String _storageKey = 'pending_tickets_queue';
  static const String _folderName = 'pending_tickets';

  Future<PendingTicketEntity> enqueue(PendingTicketCreateInput input) async {
    final localId = DateTime.now().microsecondsSinceEpoch.toString();
    final ticketDirectory = await _ticketDirectory(localId);
    await ticketDirectory.create(recursive: true);

    final savedAttachments = <PendingTicketAttachmentEntity>[];
    for (var i = 0; i < input.attachments.length; i++) {
      final attachment = input.attachments[i];
      final fileName = '${i}_${_sanitizeFileName(attachment.fileName)}';
      final file = File(
        '${ticketDirectory.path}${Platform.pathSeparator}$fileName',
      );
      await file.writeAsBytes(attachment.bytes, flush: true);
      savedAttachments.add(
        PendingTicketAttachmentEntity(
          filePath: file.path,
          fileName: attachment.fileName,
          mimeType: attachment.mimeType,
        ),
      );
    }

    final ticket = PendingTicketEntity(
      localId: localId,
      incidentTypeId: input.incidentTypeId,
      title: input.title,
      description: input.description,
      priority: input.priority,
      locationText: input.locationText,
      latitude: input.latitude,
      longitude: input.longitude,
      attachments: savedAttachments,
      createdAt: DateTime.now(),
    );

    final tickets = await list();
    tickets.add(ticket);
    await _saveAll(tickets);
    return ticket;
  }

  Future<List<PendingTicketEntity>> list() async {
    final rawItems = StorageManager.getJson<List<dynamic>>(
      _storageKey,
      defaultValue: const <dynamic>[],
    );
    return (rawItems ?? const <dynamic>[])
        .map(PendingTicketEntity.fromJson)
        .where((item) => item.localId.isNotEmpty)
        .toList();
  }

  Future<int> pendingCount() async {
    final tickets = await list();
    return tickets
        .where((item) => item.status != PendingTicketStatus.failed)
        .length;
  }

  Future<void> update(PendingTicketEntity ticket) async {
    final tickets = await list();
    final index = tickets.indexWhere((item) => item.localId == ticket.localId);
    if (index == -1) return;

    tickets[index] = ticket;
    await _saveAll(tickets);
  }

  Future<void> remove(PendingTicketEntity ticket) async {
    final tickets = await list();
    tickets.removeWhere((item) => item.localId == ticket.localId);
    await _saveAll(tickets);
    await _deleteTicketFiles(ticket.localId);
  }

  Future<void> markPendingAfterInterruptedSync() async {
    final tickets = await list();
    var changed = false;
    final updated = tickets.map((ticket) {
      if (ticket.status != PendingTicketStatus.syncing) return ticket;
      changed = true;
      return ticket.copyWith(status: PendingTicketStatus.pending);
    }).toList();

    if (changed) {
      await _saveAll(updated);
    }
  }

  Future<void> _saveAll(List<PendingTicketEntity> tickets) {
    return StorageManager.setJson(
      _storageKey,
      tickets.map((item) => item.toJson()).toList(),
    );
  }

  Future<Directory> _ticketDirectory(String localId) async {
    final root = await getApplicationDocumentsDirectory();
    return Directory(
      '${root.path}${Platform.pathSeparator}$_folderName${Platform.pathSeparator}$localId',
    );
  }

  Future<void> _deleteTicketFiles(String localId) async {
    final directory = await _ticketDirectory(localId);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  String _sanitizeFileName(String fileName) {
    final sanitized = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return sanitized.isEmpty ? 'attachment.jpg' : sanitized;
  }
}
