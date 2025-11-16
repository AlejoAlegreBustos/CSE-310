from fastapi import FastAPI
from fastapi.responses import FileResponse
from pydantic import BaseModel
import xgboost as xgb
import numpy as np
from datetime import datetime
import os

# ReportLab (PDF)
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Image
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib.pagesizes import letter
from reportlab.lib.units import inch

# Matplotlib para gráficos
import matplotlib.pyplot as plt
from io import BytesIO

# -----------------------------------------------------------
# Configuración inicial 
#uvicorn main:app --reload

# -----------------------------------------------------------

app = FastAPI()
REPORTS_DIR = "reports"
os.makedirs(REPORTS_DIR, exist_ok=True)

# Cargar modelo
model = xgb.XGBClassifier()
model.load_model(
    r"C:\Users\alejo\Desktop\BYUI\CSE-310 LOCAL\CSE-310\personal-project\module-2-interface\backendi\investment-pred.json"
)

EXPECTED_FEATURES = 289

# NO OPI{"features": [2012, 550446000.0, 833, 224294282.96453083, 4976069792.101926, false, 7, 6, 2021, 0, 2, 1, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true, false, false, false, false, false, false, false, true, false, false, false, false, false, true, false, false, true, false, false, false, false, true]}
# OPI EXIT {"features": [2007, 153685000.0, 77, 50272760.11840928, 1103388240.7296083, true, 28, 5, 2017, 6, 2, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, false, false, false, false, false, false, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true, false, false, false, false, true, false, false, false, false, false, false, false, false, false, true, false, false, false, false]}  
# -----------------------------------------------------------
# Esquemas
# -----------------------------------------------------------

class PredictionInput(BaseModel):
    features: list[float]

# -----------------------------------------------------------
# Funciones auxiliares
# -----------------------------------------------------------

def exponential_projection(current_value: float, growth_rate: float, years: int = 1):
    return current_value * np.exp(growth_rate * years)

def estimate_growth_rate(funding_amount: float):
    if funding_amount > 100_000_000:
        return 0.18
    elif funding_amount > 10_000_000:
        return 0.12
    else:
        return 0.06

def simulate_and_plot(current_value: float, growth_rate: float, n_sim: int = 1000, sigma: float = 0.2):
    """
    Simula futuros valores y genera un gráfico en memoria (BytesIO) para el PDF.
    Devuelve media, percentiles y la imagen del histograma.
    """
    simulated = np.random.lognormal(mean=np.log(current_value) + growth_rate, sigma=sigma, size=n_sim)
    mean_val = np.mean(simulated)
    p5 = np.percentile(simulated, 5)
    p95 = np.percentile(simulated, 95)
    
    # Crear histograma
    fig, ax = plt.subplots(figsize=(4, 2.5))  # tamaño en pulgadas
    ax.hist(simulated, bins=30, color='lightblue', edgecolor='black')
    ax.axvline(mean_val, color='red', linestyle='--', label='Mean')
    ax.axvline(p5, color='green', linestyle='--', label='5th percentile')
    ax.axvline(p95, color='orange', linestyle='--', label='95th percentile')
    ax.set_title("Projected distribution")
    ax.set_xlabel("USD")
    ax.set_ylabel("Frequency")
    ax.legend(fontsize=6)
    
    # Guardar figura en memoria
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
    """Genera un PDF con la predicción del modelo, revenue y valuación con gráficos."""
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"report_{timestamp}.pdf"
    filepath = os.path.join(REPORTS_DIR, filename)

    styles = getSampleStyleSheet()
    story = []

    # Growth rate
    growth_rate = estimate_growth_rate(funding_amount)

    # Simulación + gráficos
    revenue_mean, revenue_p5, revenue_p95, revenue_img = simulate_and_plot(revenue, growth_rate)
    valuation_mean, valuation_p5, valuation_p95, valuation_img = simulate_and_plot(valuation, growth_rate)

    # Título
    story.append(Paragraph("Startup Prediction Report", styles["Title"]))
    story.append(Spacer(1, 0.2 * inch))

    # Información principal
    if prediction == 1:
        prediction='IPO - High liquidity and visibility'
    else:
        prediction='Not IPO'

    info = f"""
    <b>XGBoost Prediction Exit-type:</b> {prediction}<br/>
    <b>Model confidence:</b> {confidence*100:.3f}%<br/>
    <b>Founded year:</b> {founded_year}<br/>
    <b>Funding amount USD:</b> {funding_amount:,.2f}<br/>
    <b>Employees:</b> {employees}<br/>
    <b>Current revenue:</b> {revenue:,.2f}<br/>
    <b>Current valuation:</b> {valuation:,.2f}<br/><br/>
    <b>Estimated annual growth rate:</b> {growth_rate*100:.1f}%<br/><br/>
    <b>Projected revenue (1 year):</b> {revenue_mean:,.2f} USD 
    (5%-95%: {revenue_p5:,.2f} - {revenue_p95:,.2f})<br/>
    <b>Projected valuation (1 year):</b> {valuation_mean:,.2f} USD 
    (5%-95%: {valuation_p5:,.2f} - {valuation_p95:,.2f})<br/>
    """
    story.append(Paragraph(info, styles["BodyText"]))
    story.append(Spacer(1, 0.2*inch))

    # Insertar gráficos
    story.append(Paragraph("<b>Revenue distribution:</b>", styles["BodyText"]))
    story.append(Image(revenue_img, width=400, height=250))
    story.append(Spacer(1, 0.2*inch))

    story.append(Paragraph("<b>Valuation distribution:</b>", styles["BodyText"]))
    story.append(Image(valuation_img, width=400, height=250))

    # Crear PDF
    doc = SimpleDocTemplate(filepath, pagesize=letter)
    doc.build(story)

    return filepath

# -----------------------------------------------------------
# Endpoints
# -----------------------------------------------------------

@app.post("/predict")
def predict(input_data: PredictionInput):
    X = np.array([input_data.features])

    if X.shape[1] != EXPECTED_FEATURES:
        return {"error": f"Model expects {EXPECTED_FEATURES} features, received {X.shape[1]}"}

    # Predicción XGBoost
    pred = int(model.predict(X)[0])
    prob = model.predict_proba(X)[0]          # probabilidades por clase
    conf = float(np.max(prob))                # confianza de la clase predicha

    # Extraer valores del input
    founded_year = int(input_data.features[0])
    funding_amount = float(input_data.features[1])
    employees = int(input_data.features[2])
    revenue = float(input_data.features[3])
    valuation = float(input_data.features[4])

    # Crear PDF
    pdf_path = create_pdf_report(pred, conf, revenue, valuation, funding_amount, founded_year, employees)
    pdf_filename = os.path.basename(pdf_path)

    return {
        "prediction": pred,
        "confidence": conf,
        "report_file": pdf_filename
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
