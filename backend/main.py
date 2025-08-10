from application_infastructructure import App, Shapes, Routes

if __name__ == "__main__":
    # Create and run the application
    shapes_app = Routes(
        title="Shapes Calculator",
        description="A web application to calculate areas and perimeters of shapes",
        version="1.0.0"
    )
    shapes_app.run()
