# Week 3
## Instructions
### ROS2 Basics 
For Q1, Q2 and bonus questions your src should follow the following structure.
```Only use python nodes for all submissions.``` 
#### Expected Package Structure
##### Question 1

Your workspace should contain the following package:
``` text
ros2_ws/
└── src/
    └── kratos_<your_name>/
        ├── CMakeLists.txt
        ├── package.xml
        ├── src/
        │   ├── rover_status_publisher.py
        │   └── rover_status_subscriber.py
        ├── launch/                 (Bonus)
        │   └── bringup.launch.py
        └── ...
```
##### Question 2

Create a second package for your custom message in bonus question.
```text
ros2_ws/
└── src/
    ├── kratos_<your_name>/
    │   ├── CMakeLists.txt
    │   ├── package.xml
    │   ├── src/
    │   │   ├── rover_status_msg_publisher.py
    │   │   └── rover_status_msg_subscriber.py
    │   ├── launch/                 (Bonus)
    │   │   └── bringup.launch.py
    │   └── ...
    │
    └── kratos_<your_name>_msgs/
        ├── CMakeLists.txt
        ├── package.xml
        ├── msg/
        │   └── RoverStatus.msg
        └── ...
```
Replace <your_name> with your own name.

---

### IKFK and Transforms 

##### Question 1
Question 1 is a pen-and-paper question. Upload your scanned solution to **Google Classroom**.

##### Question 2

Use the provided **arm_humble** package.

Do **not** rename the package or modify its overall directory structure unless absolutely necessary.

### Expected Package Structure

```text
arm_humble/
├── launch/
├── rviz/
├── urdf/
├── scripts/
│   └── ik_controller.py
├── CMakeLists.txt
├── package.xml
└── ...
```

### Requirements

- Create a new `scripts/` directory.
- Only use python nodes.
- Place your ROS2 node inside the `scripts/` directory.
- Modify `CMakeLists.txt` so your Python node is installed correctly.
- If additional ROS dependencies are required, update `package.xml`.
- Do not rename the package.

---

## Documentation Requirements

### Code Documentation

Every custom function **must** contain an appropriate docstring.

Example:

```python
def inverse_kinematics(x, y):
    """
    Computes the shoulder and elbow joint angles required
    to reach a target end-effector position.

    Args:
        x (float): Target x coordinate.
        y (float): Target y coordinate.

    Returns:
        tuple: (shoulder_angle, elbow_angle)
    """
```

### Repository Documentation

Your repository must contain a `README.md` describing:

- Your approach to solving the problem.
- Any assumptions you made.
- Challenges encountered.
- How you tested your implementation.
- Any known limitations.

## Submission Guidelines

1. Use the **same private GitHub repository** that you created for the previous week's assignment.
2. Push your completed implementation to your private repository.
3. Submit the **GitHub repository link** on Google Classroom before the deadline.
4. Ensure that your repository contains:

   * Your updated `src/` directory.
   * Any new packages created as part of the assignment in required structure in src.
   * Updated `CMakeLists.txt` and `package.xml` files (where applicable).
   * A `README.md` documenting your approach, assumptions, challenges faced, and testing methodology.
5. Ensure that all custom functions include appropriate docstrings and that your code is sufficiently documented to explain any non-trivial logic.
6. Add videos of all required questions' scripts working to `Google Classroom`.  

> **Note:** Do not create a new repository for each assignment. Continue using the same private repository throughout the induction process so that your progress and commit history can be reviewed over time.
