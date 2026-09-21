import 'package:flutter/material.dart';

import '../theme/app_text_color.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_panel.dart';

/// Реквизиты компании - нужны для подключения эквайринга (Альфа-Банк
/// требует эту информацию видимой в самом приложении/на сайте при
/// подаче заявки на интернет-эквайринг) и как стандартная страница
/// "О компании" для пользователей.
///
/// Значения ниже - ЗАГЛУШКИ. Заполни реальными данными перед сборкой:
/// TODO(grood): вписать реальные реквизиты организации.
class CompanyRequisitesScreen extends StatelessWidget {
  const CompanyRequisitesScreen({super.key});

  // Поменяй на реальные значения. Убери строки, которых у тебя нет
  // (например, КПП есть только у юрлиц, не у ИП).
  static const _rows = <(String, String)>[
    ('Полное наименование', 'ООО «ИСКУСТВЕННОЕ МЫШЛЕНИЕ»'),
    ('ИНН', '5012117757'),
    ('КПП', '501201001'),
    (
      'Юридический адрес',
      'улица Граничная, д. 36, кв./оф. ПОМЕЩ. 6, Московская область, г. Балашиха',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.adaptive.arrow_back,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Text(
                      'Реквизиты компании',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: GlassPanel(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final (label, value) in _rows) ...[
                          Text(
                            label,
                            style: TextStyle(
                              color: context.onSurfaceFaded(0.5),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            value,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
