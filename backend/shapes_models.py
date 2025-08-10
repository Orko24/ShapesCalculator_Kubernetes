import math


class ShapesCalculator(object):

    def circle_area(self, radius):
        return math.pi * (radius**2)

    def circle_circumference(self, radius):

        return 2*math.pi*radius

    def rectangle_area(self, length, width):

        return length * width

    def rectangle_perimeter(self, length, width):

        return 2 * (length + width)

    def triangle_area(self, height, base):

        return (1/2) * height * base





