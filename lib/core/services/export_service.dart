import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';

enum TransactionExportFormat { pdf, excel, csv }

class ExportService {
  static Future<void> exportTransactions({
    required TransactionExportFormat format,
    required List<TransactionModel> transactions,
    required Map<String, CategoryModel> categories,
    required String currencySymbol,
    required String periodLabel,
  }) {
    switch (format) {
      case TransactionExportFormat.pdf:
        return exportToPDF(
          transactions: transactions,
          categories: categories,
          currencySymbol: currencySymbol,
          periodLabel: periodLabel,
        );
      case TransactionExportFormat.excel:
        return exportToExcel(
          transactions: transactions,
          categories: categories,
          currencySymbol: currencySymbol,
        );
      case TransactionExportFormat.csv:
        return exportToCSV(transactions: transactions, categories: categories);
    }
  }

  static Future<void> exportToPDF({
    required List<TransactionModel> transactions,
    required Map<String, CategoryModel> categories,
    required String currencySymbol,
    required String periodLabel,
  }) async {
    final pdf = pw.Document();

    final font = await rootBundle.load("assets/fonts/Poppins-Regular.ttf");
    final ttf = pw.Font.ttf(font);
    final fontBold = await rootBundle.load("assets/fonts/Poppins-Bold.ttf");
    final ttfBold = pw.Font.ttf(fontBold);

    double totalIncome = 0;
    double totalExpense = 0;

    for (var t in transactions) {
      if (t.type == TransactionType.income) {
        totalIncome += t.amount;
      } else if (t.type == TransactionType.expense) {
        totalExpense += t.amount;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
        header: (context) => _buildHeader(periodLabel),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildSummarySection(totalIncome, totalExpense, currencySymbol),
          pw.SizedBox(height: 20),
          pw.Text(
            'Transaction History',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          _buildTransactionTable(transactions, categories, currencySymbol),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/expense_report.pdf');
    await file.writeAsBytes(await pdf.save());

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'Expense Report'),
    );
  }

  static pw.Widget _buildHeader(String periodLabel) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Expense Tracker',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.deepPurple,
                  ),
                ),
                pw.Text(
                  'Financial Report',
                  style: const pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Generated on: ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  'Period: $periodLabel',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(thickness: 2, color: PdfColors.deepPurple),
        pw.SizedBox(height: 20),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated by Expense Tracker App',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSummarySection(
    double totalIncome,
    double totalExpense,
    String currencySymbol,
  ) {
    final balance = totalIncome - totalExpense;
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            'Total Income',
            totalIncome,
            currencySymbol,
            PdfColors.green700,
          ),
          _buildVerticalDivider(),
          _buildSummaryItem(
            'Total Expense',
            totalExpense,
            currencySymbol,
            PdfColors.red700,
          ),
          _buildVerticalDivider(),
          _buildSummaryItem(
            'Net Balance',
            balance,
            currencySymbol,
            balance >= 0 ? PdfColors.blue700 : PdfColors.orange700,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildVerticalDivider() {
    return pw.Container(height: 40, width: 1, color: PdfColors.grey400);
  }

  static pw.Widget _buildSummaryItem(
    String label,
    double amount,
    String currencySymbol,
    PdfColor color,
  ) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '$currencySymbol${amount.toStringAsFixed(2)}',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTransactionTable(
    List<TransactionModel> transactions,
    Map<String, CategoryModel> categories,
    String currencySymbol,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue50),
          children: [
            _buildTableCell('Date', isHeader: true),
            _buildTableCell('Title', isHeader: true),
            _buildTableCell('Category', isHeader: true),
            _buildTableCell('Type', isHeader: true),
            _buildTableCell(
              'Amount',
              isHeader: true,
              alignment: pw.Alignment.centerRight,
            ),
          ],
        ),
        ...transactions.map((t) {
          final category = categories[t.categoryId];
          final isExpense = t.type == TransactionType.expense;
          final amountPrefix = isExpense ? '-' : '+';
          final amountColor = isExpense ? PdfColors.red700 : PdfColors.green700;

          return pw.TableRow(
            children: [
              _buildTableCell(DateFormat('MMM d, yyyy').format(t.date)),
              _buildTableCell(t.title),
              _buildTableCell(category?.name ?? 'Unknown'),
              _buildTableCell(
                t.type.name.toUpperCase().substring(0, 1) +
                    t.type.name.substring(1),
              ),
              _buildTableCell(
                '$amountPrefix$currencySymbol${t.amount.toStringAsFixed(2)}',
                alignment: pw.Alignment.centerRight,
                textColor: amountColor,
                isBold: true,
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.Alignment alignment = pw.Alignment.centerLeft,
    PdfColor? textColor,
    bool isBold = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      alignment: alignment,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : null,
          fontSize: isHeader ? 11 : 10,
          color: textColor ?? (isHeader ? PdfColors.blue900 : PdfColors.black),
        ),
      ),
    );
  }

  static Future<void> exportToExcel({
    required List<TransactionModel> transactions,
    required Map<String, CategoryModel> categories,
    required String currencySymbol,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Transactions'];

    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Title'),
      TextCellValue('Category'),
      TextCellValue('Type'),
      TextCellValue('Amount'),
      TextCellValue('Note'),
    ]);

    for (var t in transactions) {
      final category = categories[t.categoryId];
      sheet.appendRow([
        TextCellValue(DateFormat('yyyy-MM-dd').format(t.date)),
        TextCellValue(t.title),
        TextCellValue(category?.name ?? 'Unknown'),
        TextCellValue(t.type.name),
        DoubleCellValue(t.amount),
        TextCellValue(t.note ?? ''),
      ]);
    }

    if (excel.getDefaultSheet() != null &&
        excel.getDefaultSheet() != 'Transactions') {
      excel.delete(excel.getDefaultSheet()!);
    }

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/expense_report.xlsx');
    await file.writeAsBytes(excel.encode()!);

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'Expense Report'),
    );
  }

  static Future<void> exportToCSV({
    required List<TransactionModel> transactions,
    required Map<String, CategoryModel> categories,
  }) async {
    final buffer = StringBuffer();

    buffer.writeln('Date,Title,Category,Type,Amount,Note');

    for (var t in transactions) {
      final category = categories[t.categoryId];
      final title = _sanitizeCsvCell(t.title);
      final note = _sanitizeCsvCell(t.note ?? '');
      final categoryName = _sanitizeCsvCell(category?.name ?? 'Unknown');

      buffer.writeln(
        '${DateFormat('yyyy-MM-dd').format(t.date)},'
        '"$title",'
        '"$categoryName",'
        '${t.type.name},'
        '${t.amount},'
        '"$note"',
      );
    }

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/expense_report.csv');
    await file.writeAsString(buffer.toString());

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'Expense Report'),
    );
  }

  static String _sanitizeCsvCell(String value) {
    final escaped = value.replaceAll('"', '""');
    if (escaped.isEmpty) return escaped;

    final trimmed = escaped.trimLeft();
    if (trimmed.isNotEmpty &&
        (trimmed.startsWith('=') ||
            trimmed.startsWith('+') ||
            trimmed.startsWith('-') ||
            trimmed.startsWith('@'))) {
      return "'$escaped";
    }

    return escaped;
  }
}
