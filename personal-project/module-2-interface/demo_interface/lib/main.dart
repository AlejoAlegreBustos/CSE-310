import 'package:flutter/material.dart';

// Entry point of the app
void main() {
  runApp(const MyApp());
}

// Root widget of the application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo interface', // app title
      theme: ThemeData(
        // app theme, main color
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 70, 132, 238),
        ),
      ),
      home: const MyHomePage(title: 'form interface'), // main screen
    );
  }
}

// Main page widget (stateful because there is interaction)
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title; // title shown in AppBar

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text controllers for each column of the form
  final TextEditingController startupIdController = TextEditingController();
  final TextEditingController startupNameController = TextEditingController();
  final TextEditingController foundedYearController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController regionController = TextEditingController();
  final TextEditingController industryController = TextEditingController();
  final TextEditingController fundingRoundController = TextEditingController();
  final TextEditingController fundingAmountUsdController = TextEditingController();
  final TextEditingController fundingDateController = TextEditingController();
  final TextEditingController leadInvestorController = TextEditingController();
  final TextEditingController coInvestorsController = TextEditingController();
  final TextEditingController employeeCountController = TextEditingController();
  final TextEditingController estimatedRevenueUsdController = TextEditingController();
  final TextEditingController estimatedValuationUsdController = TextEditingController();
  final TextEditingController tagsController = TextEditingController();

  // Function called when "Send" button is pressed
  void _submitForm() {
    if (_formKey.currentState!.validate()) { // validate that all fields are filled
      final data = {
        'startup_id': startupIdController.text,
        'startup_name': startupNameController.text,
        'founded_year': foundedYearController.text,
        'country': countryController.text,
        'region': regionController.text,
        'industry': industryController.text,
        'funding_round': fundingRoundController.text,
        'funding_amount_usd': fundingAmountUsdController.text,
        'funding_date': fundingDateController.text,
        'lead_investor': leadInvestorController.text,
        'co_investors': coInvestorsController.text,
        'employee_count': employeeCountController.text,
        'estimated_revenue_usd': estimatedRevenueUsdController.text,
        'estimated_valuation_usd': estimatedValuationUsdController.text,
        'tags': tagsController.text,
      };

      // Show message on screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data submitted: ${data['startup_name']}')),
      );

      // Print data to console (useful for debugging)
      print(data);

      // Here you could send the data to Supabase or another database
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Top AppBar
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      // Main content of the page
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // allows scrolling if there are many fields
          child: Form(
            key: _formKey, // assign key for validation
            child: Column(
              children: [
                const Text(
                  'Startup info',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                // Text fields generated using the helper function
                _buildTextField('Startup ID', startupIdController),
                _buildTextField('Startup Name', startupNameController),
                _buildTextField('Founded Year', foundedYearController, isNumber: true),
                _buildTextField('Country', countryController),
                _buildTextField('Region', regionController),
                _buildTextField('Industry', industryController),
                _buildTextField('Funding Round', fundingRoundController),
                _buildTextField('Funding Amount USD', fundingAmountUsdController, isNumber: true),
                _buildTextField('Funding Date', fundingDateController),
                _buildTextField('Lead Investor', leadInvestorController),
                _buildTextField('Co-Investors', coInvestorsController),
                _buildTextField('Employee Count', employeeCountController, isNumber: true),
                _buildTextField('Estimated Revenue USD', estimatedRevenueUsdController, isNumber: true),
                _buildTextField('Estimated Valuation USD', estimatedValuationUsdController, isNumber: true),
                _buildTextField('Tags', tagsController),

                const SizedBox(height: 24),
                // Send button
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  textStyle: const TextStyle(
                    color: Color.fromARGB(255, 69, 100, 222), // color del texto
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('Send'),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper function that creates a TextFormField with a label and controller
  // If isNumber is true, the keyboard will be numeric
  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0), // space below the field
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label, // label shown above the field
          border: const OutlineInputBorder(), // rectangular border
        ),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text, // keyboard type
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label'; // error message if empty
          }
          return null; // validation successful
        },
      ),
    );
  }
}
