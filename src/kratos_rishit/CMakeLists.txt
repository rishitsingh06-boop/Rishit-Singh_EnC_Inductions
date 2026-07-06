cmake_minimum_required(VERSION 3.8)
project(kratos_rishit)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# find dependencies
find_package(ament_cmake REQUIRED)
find_package(rclpy REQUIRED)
find_package(kratos_rishit_msgs REQUIRED)

if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)

  set(ament_cmake_copyright_FOUND TRUE)
  set(ament_cmake_cpplint_FOUND TRUE)

  ament_lint_auto_find_test_dependencies()
endif()

install(PROGRAMS
  src/rover_status_msg_publisher.py
  DESTINATION lib/${PROJECT_NAME}
  RENAME rover_status_msg_publisher
)

install(PROGRAMS
  src/rover_status_msg_subscriber.py
  DESTINATION lib/${PROJECT_NAME}
  RENAME rover_status_msg_subscriber
)

install(
  DIRECTORY launch
  DESTINATION share/${PROJECT_NAME}
)

ament_package()