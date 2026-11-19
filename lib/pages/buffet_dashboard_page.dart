import 'package:flutter/material.dart';

class BuffetTicket {
  const BuffetTicket({
    required this.pickupCode,
    required this.studentName,
    required this.studentReference,
    required this.itemsSummary,
    required this.status,
  });

  final String pickupCode;
  final String studentName;
  final String studentReference;
  final String itemsSummary;
  final BuffetTicketStatus status;
}

enum BuffetTicketStatus { preparing, toDeliver, inPersonPayment }

enum BuffetTicketAction { markReady, reject, deliver }

typedef BuffetTicketActionCallback =
    void Function(BuffetTicket ticket, BuffetTicketAction action);

class TableroBuffetScreen extends StatelessWidget {
  const TableroBuffetScreen({
    required this.tickets,
    required this.onAction,
    super.key,
  });

  final List<BuffetTicket> tickets;
  final BuffetTicketActionCallback onAction;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: BuffetTicketStatus.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tablero del buffet'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'En preparación'),
              Tab(text: 'Para entregar'),
              Tab(text: 'En cobro presencial'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final status in BuffetTicketStatus.values)
              _TicketList(
                tickets: tickets
                    .where((ticket) => ticket.status == status)
                    .toList(),
                onAction: onAction,
              ),
          ],
        ),
      ),
    );
  }
}

class _TicketList extends StatelessWidget {
  const _TicketList({required this.tickets, required this.onAction});

  final List<BuffetTicket> tickets;
  final BuffetTicketActionCallback onAction;

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) {
      return const Center(
        child: Text(
          'No hay comandas en este estado',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tickets.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _TicketCard(
        ticket: tickets[index],
        onAction: onAction,
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket, required this.onAction});

  final BuffetTicket ticket;
  final BuffetTicketActionCallback onAction;

  @override
  Widget build(BuildContext context) {
    final isPreparing = ticket.status == BuffetTicketStatus.preparing;
    final isPayment = ticket.status == BuffetTicketStatus.inPersonPayment;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color(0xFF1E6FFF),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.confirmation_number_outlined, color: Colors.white),
                const SizedBox(width: 10),
                const Text(
                  'RETIRO',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  ticket.pickupCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.studentName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  ticket.studentReference,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Text(
                  ticket.itemsSummary,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (isPreparing) ...[
                      FilledButton.icon(
                        onPressed: () => onAction(
                          ticket,
                          BuffetTicketAction.markReady,
                        ),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Listo'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => onAction(
                          ticket,
                          BuffetTicketAction.reject,
                        ),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Rechazar'),
                      ),
                    ],
                    if (!isPreparing)
                      FilledButton.icon(
                        onPressed: () => onAction(
                          ticket,
                          BuffetTicketAction.deliver,
                        ),
                        icon: Icon(
                          isPayment ? Icons.payments_outlined : Icons.takeout_dining,
                          size: 18,
                        ),
                        label: const Text('Entregar'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
