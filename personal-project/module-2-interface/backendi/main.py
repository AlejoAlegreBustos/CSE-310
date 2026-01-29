from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from pydantic import BaseModel
import xgboost as xgb
import numpy as np
import os
import uuid
import time  # To generate filenames based on timestamps
from datetime import datetime
from fastapi.middleware.cors import CORSMiddleware

# --- CONNECTION LIBRARIES ---
from supabase import create_client, Client # Requires 'pip install supabase'


# ReportLab (PDF)
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Image
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib.pagesizes import letter
from reportlab.lib.units import inch

# Matplotlib for charts
import matplotlib.pyplot as plt
from io import BytesIO

# INITIAL CONFIGURATION AND SUPABASE CLIENT

app = FastAPI()
REPORTS_DIR = "reports"
os.makedirs(REPORTS_DIR, exist_ok=True)

# *** IMPORTANT: REPLACE THESE KEYS WITH YOUR REAL CREDENTIALS ***
SUPABASE_URL = "https://vhhusfbogsjknjsahfyy.supabase.co" 
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." # Recommended: Use env variables

# 2. CORS MIDDLEWARE CONFIGURATION

# The origin list MUST include your Render URL (production) and dev ports (local)
origins = [
    "https://invest-app-72ob.onrender.com",
    "http://localhost:62898",
    "http://127.0.0.1:62898",
    "http://localhost:5000",
    "http://127.0.0.1:5000",
    "*", # Allow any origin (Fine for rapid dev, specific ports are better)
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,     # Allowed origins list
    allow_credentials=True,    # Allow cookies and auth headers
    allow_methods=["*"],       # Allow all methods (POST, GET, OPTIONS, etc.)
    allow_headers=["*"],       # Allow all headers
)

try:
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
except Exception as e:
    print(f"Error initializing Supabase client: {e}")


# MODEL LOADING

current_dir = os.path.dirname(os.path.abspath(__file__))
model_path = os.path.join(current_dir, "investment-pred.json")
model = xgb.Booster()
model.load_model(model_path)

EXPECTED_FEATURES = 29

 
# Schemas
 

class PredictionInput(BaseModel):
    # Required by Flutter and for Supabase logging
    user_id: str 
    features: list[float]
    title: str = "New Startup Prediction" # Used for the report title
    startup_name: str | None = None  # Startup Name/ID for the reports table

 
# Helper Functions
 

def exponential_projection(current_value: float, growth_rate: float, years: int = 1):
    """Simple deterministic projection (not used directly in the PDF)."""
    return current_value * np.exp(growth_rate * years)

def estimate_growth_rate(funding_amount: float, revenue: float, employees: int) -> float:
    """Heuristic estimate of annual growth rate."""
    # Base component by round size
    if funding_amount > 100_000_000:
        base = 0.18
    elif funding_amount > 10_000_000:
        base = 0.12
    else:
        base = 0.06

    # Size adjustment by current revenue
    if revenue > 100_000_000:
        size_factor = 0.8
    elif revenue > 10_000_000:
        size_factor = 0.9
    else:
        size_factor = 1.0

    # Light adjustment by team size
    if employees < 50:
        team_factor = 1.1
    elif employees < 200:
        team_factor = 1.0
    else:
        team_factor = 0.9

    return base * size_factor * team_factor

def simulate_and_plot(current_value: float, growth_rate: float, years: int = 1, n_sim: int = 1000, sigma: float = 0.2):
    """Simulate future values and generate a histogram image in memory (BytesIO)."""
    if current_value <= 0:
        current_value = 1.0  # avoid log(0)

    simulated = np.random.lognormal(
        mean=np.log(current_value) + growth_rate * years,
        sigma=sigma,
        size=n_sim,
    )
    mean_val = np.mean(simulated)
    p5 = np.percentile(simulated, 5)
    p95 = np.percentile(simulated, 95)

    fig, ax = plt.subplots(figsize=(4, 2.5))
    ax.hist(simulated, bins=30, color='lightblue', edgecolor='black')
    ax.axvline(mean_val, color='red', linestyle='--', label='Mean')
    ax.axvline(p5, color='green', linestyle='--', label='5th percentile')
    ax.axvline(p95, color='orange', linestyle='--', label='95th percentile')
    ax.set_title(f"Projected distribution ({years} year(s))")
    ax.set_xlabel("USD")
    ax.set_ylabel("Frequency")
    ax.legend(fontsize=6)

    img_buffer = BytesIO()
    plt.tight_layout()
    plt.savefig(img_buffer, format='PNG')
    plt.close(fig)
    img_buffer.seek(0)

    return mean_val, p5, p95, img_buffer

def create_pdf_report(
    prediction: int,
    confidence: float,
    revenue: float,
    valuation: float,
    funding_amount: float,
    founded_year: int,
    employees: int
) -> str:
    """Generates a PDF with model prediction, revenue, and valuation charts."""
    
    # Filename is now generated in /predict (with user_id and timestamp)
    # only using timestamp here for the temporary name
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")
    filename = f"temp_report_{timestamp}.pdf"
    filepath = os.path.join(REPORTS_DIR, filename)

    styles = getSampleStyleSheet()
    story = []

    growth_rate = estimate_growth_rate(funding_amount, revenue, employees)

    # 1-year simulation
    revenue_mean_1, revenue_p5_1, revenue_p95_1, revenue_img = simulate_and_plot(
        revenue, growth_rate, years=1, sigma=0.15,
    )
    valuation_mean_1, valuation_p5_1, valuation_p95_1, valuation_img = simulate_and_plot(
        valuation, growth_rate, years=1, sigma=0.25,
    )

    # 3-year simulation (data only)
    revenue_mean_3, revenue_p5_3, revenue_p95_3, _ = simulate_and_plot(
        revenue, growth_rate, years=3, sigma=0.18,
    )
    valuation_mean_3, valuation_p5_3, valuation_p95_3, _ = simulate_and_plot(
        valuation, growth_rate, years=3, sigma=0.3,
    )

    story.append(Paragraph("Startup Prediction Report", styles["Title"]))
    story.append(Spacer(1, 0.2 * inch))

    prediction_text = 'IPO - High liquidity and visibility' if prediction == 1 else 'Not IPO'

    info = f"""
    <b>XGBoost Prediction Exit-type:</b> {prediction_text}<br/>
    <b>Model confidence:</b> {confidence*100:.3f}%<br/>
    <b>Founded year:</b> {founded_year}<br/>
    <b>Funding amount USD:</b> {funding_amount:,.2f}<br/>
    <b>Employees:</b> {employees}<br/>
    <b>Current annual revenue:</b> {revenue:,.2f}<br/>
    <b>Current valuation:</b> {valuation:,.2f}<br/><br/>
    <b>Estimated annual growth rate:</b> {growth_rate*100:.1f}%<br/><br/>
    <b>Projected revenue in 1 year:</b> {revenue_mean_1:,.2f} USD<br/>
    <b>Projected valuation in 1 year:</b> {valuation_mean_1:,.2f} USD<br/><br/>
    <b>Projected revenue in 3 years:</b> {revenue_mean_3:,.2f} USD<br/>
    <b>Projected valuation in 3 years:</b> {valuation_mean_3:,.2f} USD<br/><br/>
    """
    story.append(Paragraph(info, styles["BodyText"]))
    story.append(Spacer(1, 0.2*inch))

    story.append(Paragraph("<b>Revenue distribution (1 year):</b>", styles["BodyText"]))
    story.append(Image(revenue_img, width=400, height=250))
    story.append(Spacer(1, 0.2*inch))

    story.append(Paragraph("<b>Valuation distribution (1 year):</b>", styles["BodyText"]))
    story.append(Image(valuation_img, width=400, height=250))

    doc = SimpleDocTemplate(filepath, pagesize=letter)
    doc.build(story)

    return filepath

 
# Endpoints
 

@app.post("/predict")
def predict(input_data: PredictionInput):
    # --- 1. Prediction and PDF Creation ---
    X = np.array([input_data.features])

    if X.shape[1] != EXPECTED_FEATURES:
        raise HTTPException(
            status_code=400, 
            detail=f"Model expects {EXPECTED_FEATURES} features, received {X.shape[1]}"
        )

    # FIX: Inject feature names from the model into the DMatrix to avoid ValueError
    feature_names = model.feature_names
    dtest = xgb.DMatrix(X, feature_names=feature_names)

    # Get prediction probability
    prediction = model.predict(dtest)
    prob_val = float(prediction[0]) 

    # Determine class (threshold 0.5)
    pred_int = 1 if prob_val > 0.5 else 0

    # Calculate confidence level
    conf = prob_val if pred_int == 1 else (1.0 - prob_val)
    pred_label = 'IPO' if pred_int == 1 else 'NO IPO'

    # Extract values for PDF generation
    founded_year = int(input_data.features[0])
    funding_amount = float(input_data.features[1])
    employees = int(input_data.features[2])
    revenue = float(input_data.features[3])
    valuation = float(input_data.features[4])

    # Create PDF (returns temp path)
    temp_pdf_path = create_pdf_report(pred_int, conf, revenue, valuation, funding_amount, founded_year, employees)
    
    # Generate final filename and rename the PDF
    timestamp_key = int(time.time())
    pdf_filename = f"report_{input_data.user_id}_{timestamp_key}.pdf"
    final_pdf_path = os.path.join(REPORTS_DIR, pdf_filename)
    os.rename(temp_pdf_path, final_pdf_path) 

    # 2. Supabase

    try:
        report_uuid = str(uuid.uuid4()) # Unique ID for PK

        data_to_save = {
            # Exact column names from 'reports' table
            'reportid': report_uuid,
            'model-used': 'XGBoost v1.0',
            'version': 1,
            'creation-date': datetime.now().strftime('%Y-%m-%d'),
            'report_url': pdf_filename,
            'confidence': conf,
            'IPO_NO IPO': pred_label,
            'user_id': input_data.user_id,
        }

        response = supabase.table('reports').insert(data_to_save).execute()
        saved_report = response.data[0] if response.data else data_to_save
        report_id = saved_report.get('reportid', report_uuid)

    except Exception as e:
        print(f"SUPABASE INSERTION ERROR: {e}")
        report_id = None

    # 3. Return response to flutter 
    return {
        "prediction": pred_int,
        "confidence": conf,
        "report_file": pdf_filename,
        "report_id": report_id
    }

@app.get("/download/{filename}")
def download_report(filename: str):
    filepath = os.path.join(REPORTS_DIR, filename)
    if os.path.exists(filepath):
        return FileResponse(path=filepath, filename=filename, media_type="application/pdf")
    return {"error": "File not found"}

@app.get("/health")
def health():
    return {"status": "ok"}