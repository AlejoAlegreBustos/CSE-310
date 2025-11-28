import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/provider_form.dart';

class SecondPage extends StatelessWidget {
  const SecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StartupFormProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Form Interface'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Form(
            key: provider.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Startup info',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Founded Year
                provider.buildTextField(
                  'Founded Year',
                  provider.foundedYearController,
                  isNumber: true,
                ),
                const SizedBox(height: 8),

                // Employee Count
                provider.buildTextField(
                  'Employee Count',
                  provider.employeeCountController,
                  isNumber: true,
                ),
                const SizedBox(height: 8),

                // Funding Amount
                provider.buildTextField(
                  'Funding Amount USD',
                  provider.fundingAmountUsdController,
                  isNumber: true,
                ),
                const SizedBox(height: 8),

                // Funding Date
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Funding Date',
                    border: OutlineInputBorder(),
                  ),
                  child: ListTile(
                    title: Text(
                      provider.fundingDate == null
                          ? 'Select date'
                          : provider.fundingDate!
                              .toLocal()
                              .toIso8601String()
                              .split('T')
                              .first,
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async => await provider.pickFundingDate(context),
                  ),
                ),
                const SizedBox(height: 8),

                // Funding Round
                provider.buildDropdown(
                  'Funding Round',
                  provider.fundingRound,
                  provider.fundingRounds,
                  provider.setFundingRound,
                ),
                provider.buildOtherField(
                  provider.fundingRound,
                  provider.otherFundingRoundController,
                  'Specify Other Funding Round',
                ),
                const SizedBox(height: 8),

                // Co-investors
                provider.buildTextField(
                  'Co-investors count',
                  provider.coInvestorsCountController,
                  isNumber: true,
                ),
                const SizedBox(height: 8),

                // Lead Investor
                provider.buildDropdown(
                  'Lead Investor',
                  provider.leadInvestor,
                  provider.leadInvestors,
                  provider.setLeadInvestor,
                ),
                provider.buildOtherField(
                  provider.leadInvestor,
                  provider.otherLeadInvestorController,
                  'Specify Other Lead Investor',
                ),
                const SizedBox(height: 8),

                // Country
                provider.buildDropdown(
                  'Country',
                  provider.country,
                  provider.countriesList,
                  provider.setCountry,
                ),
                provider.buildOtherField(
                  provider.country,
                  provider.otherCountryController,
                  'Specify Other Country',
                ),
                const SizedBox(height: 8),

                // Region
                provider.buildDropdown(
                  'Region',
                  provider.region,
                  provider.regions,
                  provider.setRegion,
                ),
                provider.buildOtherField(
                  provider.region,
                  provider.otherRegionController,
                  'Specify Other Region',
                ),
                const SizedBox(height: 8),

                // Industry
                provider.buildDropdown(
                  'Industry',
                  provider.industry,
                  provider.industries,
                  provider.setIndustry,
                ),
                provider.buildOtherField(
                  provider.industry,
                  provider.otherIndustryController,
                  'Specify Other Industry',
                ),
                const SizedBox(height: 8),

                // Revenue & Valuation
                provider.buildTextField(
                  'Estimated Revenue USD',
                  provider.estimatedRevenueUsdController,
                  isNumber: true,
                ),
                const SizedBox(height: 8),
                provider.buildTextField(
                  'Estimated Valuation USD',
                  provider.estimatedValuationUsdController,
                  isNumber: true,
                ),
                const SizedBox(height: 8),

                // Exited
                SizedBox(
                  width: 150,
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Exited'),
                    value: provider.exited,
                    onChanged: (v) => provider.setExited(v ?? false),
                  ),
                ),
                const SizedBox(height: 15),

                // Tags
                const Text('Tags'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: provider.tags.keys.map((key) {
                    return FilterChip(
                      label: Text(key.replaceFirst('tag_', '')),
                      selected: provider.tags[key] ?? false,
                      onSelected: (sel) => provider.setTag(key, sel),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Buttons
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        if (!provider.validateForm()) return;

                        final jsonData = provider.buildJsonForApi();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Form submitted! Check console')),
                        );

                        final record = provider.buildRecord();
                        print('--- Form Data ---');
                        record.forEach((key, value) => print('$key: $value'));
                        print('--- JSON for API ---');
                        print(jsonData);
                      },
                      child: const Text('Submit Form'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => provider.resetForm(),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
