import 'package:flutter/material.dart';

class BookingSearchPanel extends StatelessWidget {
  const BookingSearchPanel({
    Key? key,
    required this.destinationController,
    required this.selectedDate,
    required this.guestCount,
    required this.onDateChanged,
    required this.onGuestCountChanged,
    required this.onSearchPressed,
    required this.onClearPressed,
  }) : super(key: key);

  final TextEditingController destinationController;
  final DateTime selectedDate;
  final int guestCount;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<int> onGuestCountChanged;
  final VoidCallback onSearchPressed;
  final VoidCallback onClearPressed;

  Future<void> _pickDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      onDateChanged(pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const _FieldLabel('Destination'),
            const SizedBox(height: 8),
            TextField(
              key: const Key('destinationField'),
              controller: destinationController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSearchPressed(),
              decoration: InputDecoration(
                hintText: 'City, area, hotel, or amenity',
                prefixIcon: const Icon(Icons.location_on_outlined),
                filled: true,
                fillColor: const Color(0xFFF8FAFB),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE0E6EA)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF143D36)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: _DateSelector(
                    selectedDate: selectedDate,
                    onPressed: () => _pickDate(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GuestStepper(
                    guestCount: guestCount,
                    onChanged: onGuestCountChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.search),
                    label: const Text('Search hotels'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE66A4E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: onSearchPressed,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Clear filters',
                  icon: const Icon(Icons.refresh),
                  color: const Color(0xFF143D36),
                  onPressed: onClearPressed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label, {Key? key}) : super(key: key);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF52616A),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    Key? key,
    required this.selectedDate,
    required this.onPressed,
  }) : super(key: key);

  final DateTime selectedDate;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _InputButton(
      tooltip: 'Choose check-in date',
      icon: Icons.calendar_today_outlined,
      value: _formatDate(selectedDate),
      onPressed: onPressed,
    );
  }

  String _formatDate(DateTime date) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}';
  }
}

class _GuestStepper extends StatelessWidget {
  const _GuestStepper({
    Key? key,
    required this.guestCount,
    required this.onChanged,
  }) : super(key: key);

  final int guestCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        border: Border.all(color: const Color(0xFFE0E6EA)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: 'Decrease guests',
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.remove, size: 18),
            color: const Color(0xFF143D36),
            onPressed: guestCount > 1 ? () => onChanged(guestCount - 1) : null,
          ),
          Expanded(
            child: Text(
              '$guestCount ${guestCount == 1 ? 'guest' : 'guests'}',
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF172026),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Increase guests',
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.add, size: 18),
            color: const Color(0xFF143D36),
            onPressed: guestCount < 6 ? () => onChanged(guestCount + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _InputButton extends StatelessWidget {
  const _InputButton({
    Key? key,
    required this.tooltip,
    required this.icon,
    required this.value,
    required this.onPressed,
  }) : super(key: key);

  final String tooltip;
  final IconData icon;
  final String value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFB),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Tooltip(
          message: tooltip,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE0E6EA)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 20, color: const Color(0xFF143D36)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF172026),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
