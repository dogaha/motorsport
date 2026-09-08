import io
import random
import constants
from faker import Faker

# random generated data:
def new_track():
    fake = Faker()
    state = fake.state()
    city = fake.city()
    lap_length = random.randint(2,8),
    start_coordinates = (random.randint(-100,100),random.randint(-100,100))
    end_coordinate = (random.randint(-100,100),random.randint(-100,100))
    name = f"{city} {random.choice(constants.TRACK_SUFFIXES)}"
    return

def new_driver():
    return

def modify_vehicle():
    return

def modify_driver():
    return

# Add a new record (drivers,tracks+track_turns)
def insert_record():
    return

# Edit specific fields of an existing record (vehicles,drivers)
def edit_record():
    return

if __name__ == "__main__":
    print("hello world")
