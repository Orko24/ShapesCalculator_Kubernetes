from shapes_models import ShapesCalculator
from fastapi import FastAPI, HTTPException, Depends, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, field_validator
from typing import List, Optional
import pandas as pd
import asyncio
from datetime import datetime
import uvicorn
from fastapi.responses import FileResponse
import os


class Shapes(BaseModel):
    radius: Optional[float] = None
    base: Optional[float] = None
    height: Optional[float] = None
    length: Optional[float] = None
    width: Optional[float] = None

    @field_validator('radius', 'base', 'height', 'length', 'width')
    @classmethod
    def value_must_be_positive(cls, v):
        if v is not None and v <= 0:
            raise ValueError("The value you entered must be positive")
        return v


class App:
    """Base FastAPI application class"""

    def __init__(self, title, description, version="1.0.0"):
        self.app = FastAPI(title=title, description=description, version=version)
        self.title = title
        self.description = description
        self.version = version

        # Initialize middleware
        self.middleware()

    def middleware(self):
        """Setup CORS and other middleware"""
        app = self.app
        app.add_middleware(
            CORSMiddleware,
            allow_origins=["*"],
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["*"],
        )

        # Mount static files if they exist
        frontend_path = os.environ.get('FRONTEND_PATH', '../frontend')
        static_path = os.path.join(frontend_path, 'static')
        if os.path.exists(static_path):
            app.mount("/static", StaticFiles(directory=static_path), name="static")


class Routes(App, ShapesCalculator):
    """Main routes class that handles both frontend and API routes"""

    def __init__(self, title, description, version="1.0.0"):
        App.__init__(self, title, description, version=version)
        ShapesCalculator.__init__(self)

        # Setup routes
        self.setup_routes()

    def setup_routes(self):
        """Setup all routes (frontend and API)"""
        self.frontend_routes()
        self.api_routes()

    def frontend_routes(self):
        """Setup frontend routes to serve HTML pages"""

        @self.app.get("/")
        def serve_home():
            """Serve the main index page"""
            frontend_path = os.environ.get('FRONTEND_PATH', '../frontend')
            index_path = os.path.join(frontend_path, 'index.html')
            if os.path.exists(index_path):
                return FileResponse(index_path)
            else:
                return {
                    "message": "Welcome to Shapes Calculator API",
                    "available_endpoints": ["/health", "/circle", "/rectangle", "/triangle"]
                }

        @self.app.get("/circle-page")
        def serve_circle_page():
            """Serve circle calculator page"""
            frontend_path = os.environ.get('FRONTEND_PATH', '../frontend')
            circle_path = os.path.join(frontend_path, 'circle.html')
            if os.path.exists(circle_path):
                return FileResponse(circle_path)
            return {"error": "Circle page not found"}

        @self.app.get("/rectangle-page")
        def serve_rectangle_page():
            """Serve rectangle calculator page"""
            frontend_path = os.environ.get('FRONTEND_PATH', '../frontend')
            rectangle_path = os.path.join(frontend_path, 'rectangle.html')
            if os.path.exists(rectangle_path):
                return FileResponse(rectangle_path)
            return {"error": "Rectangle page not found"}

        @self.app.get("/triangle-page")
        def serve_triangle_page():
            """Serve triangle calculator page"""
            frontend_path = os.environ.get('FRONTEND_PATH', '../frontend')
            triangle_path = os.path.join(frontend_path, 'triangle.html')
            if os.path.exists(triangle_path):
                return FileResponse(triangle_path)
            return {"error": "Triangle page not found"}

    def api_routes(self):
        """Setup API routes for calculations"""

        @self.app.get('/health')
        def health_check():
            """Health check endpoint"""
            return {
                "status": "healthy",
                "timestamp": datetime.now(),
                "service": "Shapes Calculator API"
            }

        @self.app.post('/circle')
        def calculate_circle(shape: Shapes):
            """Calculate circle area and circumference"""
            if shape.radius is None:
                raise HTTPException(status_code=400, detail="Radius is required")

            try:
                # result = self.circle_area(shape.radius)
                # print(result)

                result = {
                    "area": self.circle_area(shape.radius),
                    "circumference": self.circle_circumference(shape.radius)
                }

                return result  # Return the result directly to match your HTML expectations
            except Exception as e:
                raise HTTPException(status_code=500, detail=str(e))

        @self.app.post('/rectangle')
        def calculate_rectangle(shape: Shapes):
            """Calculate rectangle area and perimeter"""
            if shape.length is None or shape.width is None:
                raise HTTPException(status_code=400, detail="Length and width are required")

            try:
                # result = self.rectangle_area(length=shape.length, width=shape.width)

                result = {
                    'area': self.rectangle_area(length=shape.length, width=shape.width),
                    'perimeter': self.rectangle_perimeter(length=shape.length, width=shape.width)
                }

                return result  # Return the result directly to match your HTML expectations
            except Exception as e:
                raise HTTPException(status_code=500, detail=str(e))

        @self.app.post('/triangle')
        def calculate_triangle(shape: Shapes):
            """Calculate triangle area"""
            if shape.base is None or shape.height is None:
                raise HTTPException(status_code=400, detail="Base and height are required")

            try:

                result = {
                    "area": self.triangle_area(base=shape.base, height=shape.height)
                }

                return result  # Return the result directly to match your HTML expectations
            except Exception as e:
                raise HTTPException(status_code=500, detail=str(e))

    def run(self, host='0.0.0.0', port=8000, reload=False):
        """Run the FastAPI application"""
        print(f"Starting {self.title} on http://{host}:{port}")
        uvicorn.run(self.app, host=host, port=port, reload=reload)

