import 'package:flutter/material.dart';

import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../trainer_offer.dart';
import '../trainer_service.dart';

class TrainersScreen extends StatefulWidget {
  const TrainersScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<TrainersScreen> createState() => _TrainersScreenState();
}

class _TrainersScreenState extends State<TrainersScreen> {
  final _city = TextEditingController();
  final _note = TextEditingController();
  final Set<String> _tracks = {};
  List<TrainerOffer> _offers = openingTrainerRoster;
  String? _busyId;
  String? _message;

  @override
  void initState() {
    super.initState();
    _tracks.addAll(widget.appState.trainerTracks);
    _city.text = widget.appState.trainerCity;
    _load();
  }

  @override
  void dispose() {
    _city.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final offers = await TrainerService.list();
    if (mounted) setState(() => _offers = offers);
  }

  Future<void> _optIn() async {
    if (_tracks.isEmpty) {
      setState(() => _message = 'Choose gym, diet, personal assistance, or more than one.');
      return;
    }
    widget.appState.saveTrainerOptIn(tracks: _tracks.toList(), city: _city.text);
    setState(() => _message = null);
  }

  Future<void> _request(TrainerOffer offer) async {
    final id = widget.appState.userId;
    if (id == null) return;
    setState(() => _busyId = offer.id);
    final intro = await TrainerService.request(
      userId: id,
      userName: widget.appState.userName.isEmpty ? 'Cura member' : widget.appState.userName,
      userEmail: widget.appState.userEmail,
      trainer: offer,
      tracks: widget.appState.trainerTracks,
      city: widget.appState.trainerCity,
      note: _note.text,
    );
    widget.appState.upsertTrainerRequest({
      'trainerId': intro.trainerId,
      'trainerName': intro.trainerName,
      'status': intro.status,
      'monthlyRateInr': offer.monthlyRateInr,
      'curaKeepsInr': offer.curaKeepsInr,
      'trainerReceivesInr': offer.trainerReceivesInr,
      'savedOnlyOnPhone': intro.savedOnlyOnPhone,
    });
    if (mounted) {
      setState(() {
        _busyId = null;
        _message = intro.savedOnlyOnPhone
            ? 'Saved on this phone. The trainer will see it when the desk is connected.'
            : 'Request sent. ${offer.name} can accept it from the trainer desk. No payment has been taken.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final muted = ink.withValues(alpha: 0.72);
    final opted = widget.appState.trainerOptedIn;
    final wanted = widget.appState.trainerTracks.toSet();
    final visible = _offers.where((offer) => offer.covers(wanted)).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Real trainer'),
        actions: [
          TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const _TrainerDeskSheet(),
            ),
            child: const Text('Trainer desk'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'A person for the gym, meals, or day-to-day help. This is not the AI coach and not a doctor.',
            style: TextStyle(height: 1.4, color: muted),
          ),
          const SizedBox(height: 12),
          Text(
            'You pay the trainer’s monthly rate. Cura keeps ${TrainerOffer.commissionPercent}% and the trainer receives the rest. Nothing is charged until the trainer accepts.',
            style: TextStyle(height: 1.4, color: ink, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Text('What do you want help with?', style: TextStyle(fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in const ['gym', 'diet', 'assist'])
                FilterChip(
                  label: Text(trackLabel(id)),
                  selected: _tracks.contains(id),
                  onSelected: (on) => setState(() => on ? _tracks.add(id) : _tracks.remove(id)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _city,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Your city',
              hintText: 'So a nearby trainer can be matched',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _optIn,
            child: Text(opted ? 'Update what I opted in for' : 'I want a real trainer'),
          ),
          if (!opted) ...[
            const SizedBox(height: 8),
            Text('Opt in before you can request someone.', style: TextStyle(color: muted)),
          ],
          if (opted) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _note,
              maxLength: 500,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Note for the trainer',
                hintText: 'Gym days, foods you already eat, or the help you want. Do not include lab reports.',
              ),
            ),
            const SizedBox(height: 8),
            for (final offer in visible) _OfferCard(
              offer: offer,
              busy: _busyId == offer.id,
              existing: widget.appState.trainerRequests.cast<Map>().where((row) => row['trainerId'] == offer.id).firstOrNull,
              onRequest: () => _request(offer),
            ),
            if (visible.isEmpty)
              Text('No collaborated trainer covers that mix yet.', style: TextStyle(color: muted)),
          ],
          if (widget.appState.trainerRequests.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Your requests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ink)),
            const SizedBox(height: 8),
            for (final row in widget.appState.trainerRequests)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${row['trainerName']} · ${_statusLabel(row['status']?.toString() ?? '')}',
                  style: TextStyle(color: ink, height: 1.35),
                ),
              ),
          ],
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(_message!, style: TextStyle(color: AppColors.primaryContainer, fontWeight: FontWeight.w600, height: 1.35)),
          ],
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'requested':
        return 'sent, waiting for the trainer';
      case 'accepted':
        return 'accepted';
      case 'declined':
        return 'declined';
      case 'saved_on_phone':
        return 'saved on this phone';
      default:
        return status;
    }
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.busy,
    required this.existing,
    required this.onRequest,
  });

  final TrainerOffer offer;
  final bool busy;
  final Map? existing;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final muted = ink.withValues(alpha: 0.7);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF2A2C3A) : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(offer.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 4),
          Text(
            '${offer.city} · ${offer.tracks.map(trackLabel).join(', ')}',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 8),
          Text(offer.bio, style: TextStyle(height: 1.35, color: ink)),
          const SizedBox(height: 10),
          Text('You pay ${rupees(offer.monthlyRateInr)} / month', style: TextStyle(fontWeight: FontWeight.w700, color: ink)),
          Text('Trainer receives ${rupees(offer.trainerReceivesInr)}', style: TextStyle(color: ink)),
          Text('Cura keeps ${rupees(offer.curaKeepsInr)} (${TrainerOffer.commissionPercent}%)', style: TextStyle(color: muted)),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: busy || existing != null ? null : onRequest,
            child: Text(busy ? 'Sending' : existing != null ? 'Requested' : 'Request this trainer'),
          ),
        ],
      ),
    );
  }
}

class _TrainerDeskSheet extends StatefulWidget {
  const _TrainerDeskSheet();

  @override
  State<_TrainerDeskSheet> createState() => _TrainerDeskSheetState();
}

class _TrainerDeskSheetState extends State<_TrainerDeskSheet> {
  final _code = TextEditingController();
  List<TrainerRequestView> _rows = const [];
  String? _trainerName;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final rows = await TrainerService.desk(_code.text);
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _trainerName = 'Your requests';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e is StateError ? e.message : 'Could not open the trainer desk.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decide(TrainerRequestView row, String status) async {
    setState(() => _busy = true);
    try {
      await TrainerService.decide(deskCode: _code.text, requestId: row.id, status: status);
      final rows = await TrainerService.desk(_code.text);
      if (mounted) setState(() => _rows = rows);
    } catch (e) {
      if (mounted) setState(() => _error = e is StateError ? e.message : 'Could not update that request.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Trainer desk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 6),
          Text(
            'Collaborated trainers enter the code Cura gave them. They see only people who asked for them.',
            style: TextStyle(height: 1.35, color: ink.withValues(alpha: 0.72)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _code,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Trainer code'),
          ),
          const SizedBox(height: 8),
          FilledButton(onPressed: _busy ? null : _open, child: Text(_busy ? 'Opening' : 'Open my requests')),
          if (_trainerName != null) ...[
            const SizedBox(height: 12),
            Text(_trainerName!, style: TextStyle(fontWeight: FontWeight.w700, color: ink)),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: TextStyle(color: AppColors.accentCoral, fontWeight: FontWeight.w600)),
            ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final row in _rows)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${row.userName} · ${row.status}', style: TextStyle(fontWeight: FontWeight.w700, color: ink)),
                        Text(
                          [row.city, row.userEmail, row.tracks.map(trackLabel).join(', ')].where((s) => s.isNotEmpty).join(' · '),
                          style: TextStyle(color: ink.withValues(alpha: 0.72)),
                        ),
                        if (row.note.isNotEmpty) Text(row.note, style: TextStyle(height: 1.35, color: ink)),
                        if (row.status == 'requested')
                          Row(
                            children: [
                              TextButton(onPressed: _busy ? null : () => _decide(row, 'accepted'), child: const Text('Accept')),
                              TextButton(onPressed: _busy ? null : () => _decide(row, 'declined'), child: const Text('Decline')),
                            ],
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
