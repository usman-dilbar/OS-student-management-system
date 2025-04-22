#!/bin/bash

# Constants
MAX_STUDENTS=20
MAX_NAME_LENGTH=50
MAX_PASSWORD_LENGTH=20
DATA_FILE="student_data.txt"
TEACHER_ID="teacher"
TEACHER_PASSWORD="admin123"

# Grade thresholds
A_GRADE_THRESHOLD=90
A_MINUS_GRADE_THRESHOLD=85
B_PLUS_GRADE_THRESHOLD=80
B_GRADE_THRESHOLD=75
B_MINUS_GRADE_THRESHOLD=70
C_PLUS_GRADE_THRESHOLD=65
C_GRADE_THRESHOLD=60
C_MINUS_GRADE_THRESHOLD=55
D_GRADE_THRESHOLD=50
PASS_CGPA=2.0

# Global variables
declare -a students_rollNo
declare -a students_name
declare -a students_password
declare -a students_totalCourses
declare -a students_cgpa
declare -a students_isActive
declare -a courses_name
declare -a courses_marks
declare -a courses_grade
declare -a courses_gradePoints

studentCount=0
userType=0
studentIndex=-1

# Function to display the main menu
displayMainMenu() {
    clear
    echo "===================================="
    echo "    STUDENT MANAGEMENT SYSTEM       "
    echo "===================================="
    echo "1. Login"
    echo "2. Exit"
    echo "===================================="
}

# Function to display the teacher menu
displayTeacherMenu() {
    clear
    echo "===================================="
    echo "         TEACHER MENU               "
    echo "===================================="
    echo "1. Add Student"
    echo "2. View Student Details"
    echo "3. Update Student Information"
    echo "4. Delete Student"
    echo "5. Assign Marks"
    echo "6. Generate Report (Ascending order by CGPA)"
    echo "7. Generate Report (Descending order by CGPA)"
    echo "8. List Passed Students"
    echo "9. List Failed Students"
    echo "10. Save Data"
    echo "11. Logout"
    echo "===================================="
}

# Function to display the student menu
displayStudentMenu() {
    clear
    echo "===================================="
    echo "         STUDENT MENU               "
    echo "===================================="
    echo "1. View Grades and CGPA"
    echo "2. Logout"
    echo "===================================="
}

# Function to authenticate user
authenticateUser() {
    local userId=$1
    local password=$2
    
    # Check if teacher credentials
    if [ "$userId" == "$TEACHER_ID" ] && [ "$password" == "$TEACHER_PASSWORD" ]; then
        echo 1
        return
    fi
    
    # Check if student credentials
    for ((i=0; i<studentCount; i++)); do
        if [ "${students_rollNo[$i]}" == "$userId" ] && [ "${students_password[$i]}" == "$password" ] && [ "${students_isActive[$i]}" -eq 1 ]; then
            echo 2
            return
        fi
    done
    
    echo 0
}

# Function to compare floating point numbers without using bc
# Returns 1 if condition is true, 0 otherwise
compare_floats() {
    local op1=$1
    local operator=$2
    local op2=$3
    
    # Convert to integers by multiplying by 100 to handle up to 2 decimal places
    # Use awk for more reliable float handling
    local op1_int=$(awk -v n="$op1" 'BEGIN {printf "%.0f", n*100}')
    local op2_int=$(awk -v n="$op2" 'BEGIN {printf "%.0f", n*100}')
    
    case $operator in
        ">")
            [ "$op1_int" -gt "$op2_int" ] && echo 1 || echo 0
            ;;
        ">=")
            [ "$op1_int" -ge "$op2_int" ] && echo 1 || echo 0
            ;;
        "<")
            [ "$op1_int" -lt "$op2_int" ] && echo 1 || echo 0
            ;;
        "<=")
            [ "$op1_int" -le "$op2_int" ] && echo 1 || echo 0
            ;;
        "==")
            [ "$op1_int" -eq "$op2_int" ] && echo 1 || echo 0
            ;;
        "!=")
            [ "$op1_int" -ne "$op2_int" ] && echo 1 || echo 0
            ;;
        *)
            echo 0
            ;;
    esac
}

# Simple math function to replace basic bc operations
simple_math() {
    local expr="$1"
    
    # Handle division specifically - using awk for more reliable float handling
    if [[ "$expr" == *"/"* ]]; then
        local op1=$(echo "$expr" | cut -d'/' -f1)
        local op2=$(echo "$expr" | cut -d'/' -f2)
        
        # Division with 2 decimal places using awk
        awk -v n1="$op1" -v n2="$op2" 'BEGIN {printf "%.2f", n1/n2}'
        return
    fi
    
    # Handle addition - using awk for more reliable float handling
    if [[ "$expr" == *"+"* ]]; then
        local op1=$(echo "$expr" | cut -d'+' -f1)
        local op2=$(echo "$expr" | cut -d'+' -f2)
        
        # Addition with 2 decimal places using awk
        awk -v n1="$op1" -v n2="$op2" 'BEGIN {printf "%.2f", n1+n2}'
        return
    fi
    
    # Just return the expression if no operations detected
    awk -v n="$expr" 'BEGIN {printf "%.2f", n}'
}

# Function to calculate grade - modified to avoid name references
calculateGrade() {
    local marks=$1
    
    # Convert to numeric to ensure proper comparison
    marks=$(awk -v n="$marks" 'BEGIN {printf "%.2f", n}')
    
    local grade=""
    local gradePoints=0.0
    
    if [ "$(compare_floats "$marks" ">=" "$A_GRADE_THRESHOLD")" -eq 1 ]; then
        grade="A"
        gradePoints=4.0
    elif [ "$(compare_floats "$marks" ">=" "$A_MINUS_GRADE_THRESHOLD")" -eq 1 ]; then
        grade="A-"
        gradePoints=3.7
    elif [ "$(compare_floats "$marks" ">=" "$B_PLUS_GRADE_THRESHOLD")" -eq 1 ]; then
        grade="B+"
        gradePoints=3.3
    elif [ "$(compare_floats "$marks" ">=" "$B_GRADE_THRESHOLD")" -eq 1 ]; then
        grade="B"
        gradePoints=3.0
    elif [ "$(compare_floats "$marks" ">=" "$B_MINUS_GRADE_THRESHOLD")" -eq 1 ]; then
        grade="B-"
        gradePoints=2.7
    elif [ "$(compare_floats "$marks" ">=" "$C_PLUS_GRADE_THRESHOLD")" -eq 1 ]; then
        grade="C+"
        gradePoints=2.3
    elif [ "$(compare_floats "$marks" ">=" "$C_GRADE_THRESHOLD")" -eq 1 ]; then
        grade="C"
        gradePoints=2.0
    elif [ "$(compare_floats "$marks" ">=" "$C_MINUS_GRADE_THRESHOLD")" -eq 1 ]; then
        grade="C-"
        gradePoints=1.7
    elif [ "$(compare_floats "$marks" ">=" "$D_GRADE_THRESHOLD")" -eq 1 ]; then
        grade="D"
        gradePoints=1.0
    else
        grade="F"
        gradePoints=0.0
    fi
    
    # Return both values as a colon-separated string
    echo "$grade:$gradePoints"
}

# Function to calculate CGPA
calculateCGPA() {
    local studentIdx=$1
    local totalCourses=${students_totalCourses[$studentIdx]}
    
    if [ "$totalCourses" -eq 0 ]; then
        echo "0.0"
        return
    fi
    
    local totalGradePoints=0.0
    local startIdx=$((studentIdx * 5))  # Assuming max 5 courses per student
    
    for ((i=0; i<totalCourses; i++)); do
        totalGradePoints=$(simple_math "$totalGradePoints + ${courses_gradePoints[$startIdx + $i]}")
    done
    
    echo $(simple_math "$totalGradePoints / $totalCourses")
}

# Function to validate that a string contains only letters, spaces and some punctuation (no numbers)
validateNameOrCourse() {
    local input=$1
    local type=$2  # "name" or "course"
    
    # Check if input is empty
    if [ -z "$input" ]; then
        echo "$type cannot be empty!"
        return 1
    fi
    
    # Check if input contains digits
    if [[ "$input" =~ [0-9] ]]; then
        echo "$type should not contain numbers!"
        return 1
    fi
    
    return 0
}

# Function to validate marks
validateMarks() {
    local marks=$1
    
    # Check if input is empty
    if [ -z "$marks" ]; then
        echo "Marks cannot be empty!"
        return 1
    fi
    
    # Check if input contains non-numeric characters
    if ! [[ "$marks" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo "Marks should contain only numbers!"
        return 1
    fi
    
    # Check if marks are negative
    if [ "$(compare_floats "$marks" "<" "0")" -eq 1 ]; then
        echo "Marks cannot be negative!"
        return 1
    fi
    
    # Check if marks are greater than 100
    if [ "$(compare_floats "$marks" ">" "100")" -eq 1 ]; then
        echo "Marks cannot be greater than 100!"
        return 1
    fi
    
    return 0
}

# Function to validate roll number
validateRollNo() {
    local rollNo=$1
    
    # Check if roll number is empty
    if [ -z "$rollNo" ]; then
        echo "Roll number cannot be empty!"
        return 1
    fi
    
    # Check if roll number starts with a hyphen
    if [[ "$rollNo" = -* ]]; then
        echo "Roll number cannot start with a hyphen (-)!"
        return 1
    fi
    
    # Check if roll number already exists (uniqueness check)
    for ((i=0; i<studentCount; i++)); do
        if [ "${students_rollNo[$i]}" == "$rollNo" ] && [ "${students_isActive[$i]}" -eq 1 ]; then
            echo "Student with this Roll Number already exists!"
            return 1
        fi
    done
    
    return 0
}

# Function to add a new student
addStudent() {
    if [ "$studentCount" -ge "$MAX_STUDENTS" ]; then
        read -p "Maximum student limit reached! Press Enter to continue..."
        return
    fi
    
    clear
    echo "===================================="
    echo "          ADD NEW STUDENT           "
    echo "===================================="
    
    # Roll number input with validation
    while true; do
        read -p "Enter Roll Number: " rollNo
        
        # Validate roll number
        validateRollNo "$rollNo"
        if [ $? -eq 0 ]; then
            break
        else
            read -p "$(validateRollNo "$rollNo") Press Enter to try again..."
        fi
    done
    
    # Name input with validation
    while true; do
        read -p "Enter Name: " name
        
        # Validate name
        validateNameOrCourse "$name" "Name"
        if [ $? -eq 0 ]; then
            break
        else
            read -p "$(validateNameOrCourse "$name" "Name") Press Enter to try again..."
        fi
    done
    
    # Password input
    read -p "Enter Password: " password
    
    # Number of courses input with validation
    while true; do
        read -p "Enter Number of Courses (max 5): " totalCourses
        
        if ! [[ "$totalCourses" =~ ^[0-9]+$ ]]; then
            read -p "Please enter a valid number! Press Enter to try again..."
            continue
        fi
        
        if [ "$totalCourses" -le 0 ]; then
            read -p "Number of courses must be at least 1! Press Enter to try again..."
            continue
        fi
        
        if [ "$totalCourses" -gt 5 ]; then
            totalCourses=5
            echo "Maximum 5 courses allowed. Setting to 5."
        fi
        break
    done
    
    # Add student to arrays
    students_rollNo[$studentCount]=$rollNo
    students_name[$studentCount]=$name
    students_password[$studentCount]=$password
    students_totalCourses[$studentCount]=$totalCourses
    students_cgpa[$studentCount]=0.0
    students_isActive[$studentCount]=1
    
    # Initialize courses
    local courseStartIdx=$((studentCount * 5))  # Assuming max 5 courses per student
    
    for ((i=0; i<totalCourses; i++)); do
        # Course name input with validation
        while true; do
            read -p "Enter Course $((i+1)) Name: " courseName
            
            # Validate course name
            validateNameOrCourse "$courseName" "Course name"
            if [ $? -eq 0 ]; then
                break
            else
                read -p "$(validateNameOrCourse "$courseName" "Course name") Press Enter to try again..."
            fi
        done
        
        courses_name[$courseStartIdx + $i]=$courseName
        courses_marks[$courseStartIdx + $i]=0.0
        courses_grade[$courseStartIdx + $i]="NA"
        courses_gradePoints[$courseStartIdx + $i]=0.0
    done
    
    ((studentCount++))
    
    read -p "Student added successfully! Press Enter to continue..."
    
    # Save data to file
    saveData
}

# Function to view student details
viewStudentDetails() {
    clear
    echo "===================================="
    echo "        VIEW STUDENT DETAILS        "
    echo "===================================="
    
    read -p "Enter Student Roll Number: " rollNo
    
    local found=0
    
    for ((i=0; i<studentCount; i++)); do
        if [ "${students_rollNo[$i]}" == "$rollNo" ] && [ "${students_isActive[$i]}" -eq 1 ]; then
            found=1
            
            echo -e "\nRoll Number: ${students_rollNo[$i]}"
            echo "Name: ${students_name[$i]}"
            echo "CGPA: ${students_cgpa[$i]}"
            echo "Courses: ${students_totalCourses[$i]}"
            
            # Fix: Add proper column headers with printf
            printf "%-20s %-10s %-5s %-10s\n" "Course Name" "Marks" "Grade" "Grade Points"
            echo "----------------------------------------------------------"
            
            local courseStartIdx=$((i * 5))
            
            for ((j=0; j<${students_totalCourses[$i]}; j++)); do
                printf "%-20s %-10.2f %-5s %-10.2f\n" \
                    "${courses_name[$courseStartIdx + $j]}" \
                    "${courses_marks[$courseStartIdx + $j]}" \
                    "${courses_grade[$courseStartIdx + $j]}" \
                    "${courses_gradePoints[$courseStartIdx + $j]}"
            done
            
            break
        fi
    done
    
    if [ "$found" -eq 0 ]; then
        read -p "Student not found! Press Enter to continue..."
    else
        read -p $'\nPress Enter to continue...'
    fi
}

# Function to update student information
updateStudentInfo() {
    clear
    echo "===================================="
    echo "    UPDATE STUDENT INFORMATION      "
    echo "===================================="
    
    read -p "Enter Student Roll Number: " rollNo
    
    local found=0
    
    for ((i=0; i<studentCount; i++)); do
        if [ "${students_rollNo[$i]}" == "$rollNo" ] && [ "${students_isActive[$i]}" -eq 1 ]; then
            found=1
            
            echo -e "\nStudent Found:"
            echo "Roll Number: ${students_rollNo[$i]}"
            echo "Name: ${students_name[$i]}"
            echo -e "\nWhat would you like to update?"
            echo "1. Name"
            echo "2. Password"
            echo "3. Course Marks"
            read -p "Enter choice: " updateChoice
            
            case $updateChoice in
                1) # Update name
                    while true; do
                        read -p "Enter new name: " newName
                        
                        # Validate name
                        validateNameOrCourse "$newName" "Name"
                        if [ $? -eq 0 ]; then
                            students_name[$i]=$newName
                            echo "Name updated successfully!"
                            break
                        else
                            read -p "$(validateNameOrCourse "$newName" "Name") Press Enter to try again..."
                        fi
                    done
                    ;;
                    
                2) # Update password
                    read -p "Enter new password: " newPassword
                    students_password[$i]=$newPassword
                    echo "Password updated successfully!"
                    ;;
                    
                3) # Update course marks
                    if [ "${students_totalCourses[$i]}" -gt 0 ]; then
                        echo -e "\nSelect course to update marks:"
                        
                        local courseStartIdx=$((i * 5))
                        
                        for ((j=0; j<${students_totalCourses[$i]}; j++)); do
                            echo "$((j+1)). ${courses_name[$courseStartIdx + $j]}"
                        done
                        
                        read -p "Enter choice: " courseChoice
                        
                        if [ "$courseChoice" -ge 1 ] && [ "$courseChoice" -le "${students_totalCourses[$i]}" ]; then
                            while true; do
                                read -p "Enter new marks for ${courses_name[$courseStartIdx + $((courseChoice-1))]}: " newMarks
                                
                                # Validate marks
                                validateMarks "$newMarks"
                                if [ $? -eq 0 ]; then
                                    courses_marks[$courseStartIdx + $((courseChoice-1))]=$newMarks
                                    
                                    # Calculate grade and grade points with new function approach
                                    local grade_result=$(calculateGrade "$newMarks")
                                    local grade=$(echo "$grade_result" | cut -d':' -f1)
                                    local gradePoints=$(echo "$grade_result" | cut -d':' -f2)
                                    
                                    # Update the arrays
                                    courses_grade[$courseStartIdx + $((courseChoice-1))]="$grade"
                                    courses_gradePoints[$courseStartIdx + $((courseChoice-1))]="$gradePoints"
                                    
                                    # Recalculate CGPA
                                    students_cgpa[$i]=$(calculateCGPA $i)
                                    
                                    echo "Marks updated successfully!"
                                    break
                                else
                                    read -p "$(validateMarks "$newMarks") Press Enter to try again..."
                                fi
                            done
                        else
                            echo "Invalid course selection!"
                        fi
                    else
                        echo "No courses available to update!"
                    fi
                    ;;
                    
                *)
                    echo "Invalid choice!"
            esac
            
            break
        fi
    done
    
    if [ "$found" -eq 0 ]; then
        read -p "Student not found! Press Enter to continue..."
    else
        read -p $'\nPress Enter to continue...'
        
        # Save data to file
        saveData
    fi
}

# Function to delete a student
deleteStudent() {
    clear
    echo "===================================="
    echo "          DELETE STUDENT            "
    echo "===================================="
    
    read -p "Enter Student Roll Number to delete: " rollNo
    
    local found=0
    
    for ((i=0; i<studentCount; i++)); do
        if [ "${students_rollNo[$i]}" == "$rollNo" ] && [ "${students_isActive[$i]}" -eq 1 ]; then
            found=1
            
            echo -e "\nStudent Found:"
            echo "Roll Number: ${students_rollNo[$i]}"
            echo "Name: ${students_name[$i]}"
            read -p $'\nAre you sure you want to delete this student? (Y/N): ' confirmation
            
            if [[ "${confirmation^^}" == "Y" ]]; then
                students_isActive[$i]=0
                echo "Student deleted successfully!"
                
                # Save data to file
                saveData
            else
                echo "Deletion cancelled."
            fi
            
            break
        fi
    done
    
    if [ "$found" -eq 0 ]; then
        read -p "Student not found! Press Enter to continue..."
    else
        read -p $'\nPress Enter to continue...'
    fi
}

# Function to assign marks to students - updated to work with new calculateGrade
assignMarks() {
    clear
    echo "===================================="
    echo "            ASSIGN MARKS            "
    echo "===================================="
    
    read -p "Enter Student Roll Number: " rollNo
    
    local found=0
    
    for ((i=0; i<studentCount; i++)); do
        if [ "${students_rollNo[$i]}" == "$rollNo" ] && [ "${students_isActive[$i]}" -eq 1 ]; then
            found=1
            
            echo -e "\nAssigning marks for ${students_name[$i]} (Roll No: ${students_rollNo[$i]})"
            
            local courseStartIdx=$((i * 5))
            
            for ((j=0; j<${students_totalCourses[$i]}; j++)); do
                while true; do
                    read -p "Enter marks for ${courses_name[$courseStartIdx + $j]} (0-100): " marks
                    
                    # Validate marks
                    validateMarks "$marks"
                    if [ $? -eq 0 ]; then
                        courses_marks[$courseStartIdx + $j]=$marks
                        
                        # Calculate grade and grade points with new function approach
                        local grade_result=$(calculateGrade "$marks")
                        local grade=$(echo "$grade_result" | cut -d':' -f1)
                        local gradePoints=$(echo "$grade_result" | cut -d':' -f2)
                        
                        # Update the arrays
                        courses_grade[$courseStartIdx + $j]="$grade"
                        courses_gradePoints[$courseStartIdx + $j]="$gradePoints"
                        break
                    else
                        read -p "$(validateMarks "$marks") Press Enter to try again..."
                    fi
                done
            done
            
            # Calculate CGPA
            students_cgpa[$i]=$(calculateCGPA $i)
            
            echo -e "\nMarks assigned successfully! CGPA: ${students_cgpa[$i]}"
            
            # Save data to file
            saveData
            
            break
        fi
    done
    
    if [ "$found" -eq 0 ]; then
        read -p "Student not found! Press Enter to continue..."
    else
        read -p $'\nPress Enter to continue...'
    fi
}

# Function to generate report - fix the printf formatting for roll numbers
generateReport() {
    clear
    echo "===================================="
    echo "          STUDENT REPORT            "
    echo "===================================="
    
    local sortOrder=$1
    
    # Count active students
    local activeCount=0
    for ((i=0; i<studentCount; i++)); do
        if [ "${students_isActive[$i]}" -eq 1 ]; then
            ((activeCount++))
        fi
    done
    
    if [ "$activeCount" -eq 0 ]; then
        read -p "No students found! Press Enter to continue..."
        return
    fi
    
    # Create temporary arrays for sorting
    local -a tempIndices
    local index=0
    
    # Get indices of active students
    for ((i=0; i<studentCount; i++)); do
        if [ "${students_isActive[$i]}" -eq 1 ]; then
            tempIndices[$index]=$i
            ((index++))
        fi
    done
    
    # Sort by CGPA
    for ((i=0; i<activeCount-1; i++)); do
        for ((j=0; j<activeCount-i-1; j++)); do
            local cgpa1=${students_cgpa[${tempIndices[$j]}]}
            local cgpa2=${students_cgpa[${tempIndices[$j+1]}]}
            
            if { [ "$sortOrder" -eq 1 ] && [ "$(compare_floats "$cgpa1" ">" "$cgpa2")" -eq 1 ]; } || \
               { [ "$sortOrder" -eq 2 ] && [ "$(compare_floats "$cgpa1" "<" "$cgpa2")" -eq 1 ]; }; then
                # Swap indices
                local temp=${tempIndices[$j]}
                tempIndices[$j]=${tempIndices[$j+1]}
                tempIndices[$j+1]=$temp
            fi
        done
    done
    
    # Print report header
    printf "%-10s %-20s %-10s %-15s\n" "Roll No" "Name" "CGPA" "Status"
    echo "----------------------------------------------------"
    
    # Print sorted student data
    for ((i=0; i<activeCount; i++)); do
        local idx=${tempIndices[$i]}
        local status="PASS"
        
        if [ "$(compare_floats "${students_cgpa[$idx]}" "<" "$PASS_CGPA")" -eq 1 ]; then
            status="FAIL"
        fi
        
        # Changed from %-10d to %-10s for roll number
        printf "%-10s %-20s %-10.2f %-15s\n" \
            "${students_rollNo[$idx]}" \
            "${students_name[$idx]}" \
            "${students_cgpa[$idx]}" \
            "$status"
    done
    
    read -p $'\nPress Enter to continue...'
}

# Function to list passed students - fix the printf formatting for roll numbers
listPassedStudents() {
    clear
    echo "===================================="
    echo "         PASSED STUDENTS            "
    echo "===================================="
    
    # Count passed students
    local passedCount=0
    for ((i=0; i<studentCount; i++)); do
        if [ "${students_isActive[$i]}" -eq 1 ] && [ "$(compare_floats "${students_cgpa[$i]}" ">=" "$PASS_CGPA")" -eq 1 ]; then
            ((passedCount++))
        fi
    done
    
    if [ "$passedCount" -eq 0 ]; then
        read -p "No passed students found! Press Enter to continue..."
        return
    fi
    
    # Print report header
    printf "%-10s %-20s %-10s\n" "Roll No" "Name" "CGPA"
    echo "----------------------------------------"
    
    # Print passed student data
    for ((i=0; i<studentCount; i++)); do
        if [ "${students_isActive[$i]}" -eq 1 ] && [ "$(compare_floats "${students_cgpa[$i]}" ">=" "$PASS_CGPA")" -eq 1 ]; then
            # Changed from %-10d to %-10s for roll number
            printf "%-10s %-20s %-10.2f\n" \
                "${students_rollNo[$i]}" \
                "${students_name[$i]}" \
                "${students_cgpa[$i]}"
        fi
    done
    
    read -p $'\nPress Enter to continue...'
}

# Function to list failed students - fix the printf formatting for roll numbers
listFailedStudents() {
    clear
    echo "===================================="
    echo "         FAILED STUDENTS            "
    echo "===================================="
    
    # Count failed students
    local failedCount=0
    for ((i=0; i<studentCount; i++)); do
        if [ "${students_isActive[$i]}" -eq 1 ] && [ "$(compare_floats "${students_cgpa[$i]}" "<" "$PASS_CGPA")" -eq 1 ]; then
            ((failedCount++))
        fi
    done
    
    if [ "$failedCount" -eq 0 ]; then
        read -p "No failed students found! Press Enter to continue..."
        return
    fi
    
    # Print report header
    printf "%-10s %-20s %-10s\n" "Roll No" "Name" "CGPA"
    echo "----------------------------------------"
    
    # Print failed student data
    for ((i=0; i<studentCount; i++)); do
        if [ "${students_isActive[$i]}" -eq 1 ] && [ "$(compare_floats "${students_cgpa[$i]}" "<" "$PASS_CGPA")" -eq 1 ]; then
            # Changed from %-10d to %-10s for roll number
            printf "%-10s %-20s %-10.2f\n" \
                "${students_rollNo[$i]}" \
                "${students_name[$i]}" \
                "${students_cgpa[$i]}"
        fi
    done
    
    read -p $'\nPress Enter to continue...'
}

# Function to save data to file
saveData() {
    > "$DATA_FILE"  # Clear the file
    
    # Write header row
    echo "# Student Management System Data File" >> "$DATA_FILE"
    echo "# Format: studentCount=$studentCount" >> "$DATA_FILE"
    echo "# STUDENT_DATA: rollNo|name|password|totalCourses|cgpa|isActive" >> "$DATA_FILE"
    echo "# COURSE_DATA: courseName|marks|grade|gradePoints" >> "$DATA_FILE"
    echo "#------------------------------------------------------------" >> "$DATA_FILE"
    
    # Write each student's data in tabular format
    for ((i=0; i<studentCount; i++)); do
        # Write student info with pipe delimiter
        echo "STUDENT|${students_rollNo[$i]}|${students_name[$i]}|${students_password[$i]}|${students_totalCourses[$i]}|${students_cgpa[$i]}|${students_isActive[$i]}" >> "$DATA_FILE"
        
        # Write course data
        local courseStartIdx=$((i * 5))
        
        for ((j=0; j<${students_totalCourses[$i]}; j++)); do
            echo "COURSE|${courses_name[$courseStartIdx + $j]}|${courses_marks[$courseStartIdx + $j]}|${courses_grade[$courseStartIdx + $j]}|${courses_gradePoints[$courseStartIdx + $j]}" >> "$DATA_FILE"
        done
        
        # Add a separator between students
        echo "#------------------------------------------------------------" >> "$DATA_FILE"
    done
}

# Fix loadData function to properly handle course indices
loadData() {
    if [ ! -f "$DATA_FILE" ]; then
        return
    fi
    
    # Initialize variables
    studentCount=0
    
    # Legacy format detection flag
    local legacyFormat=false
    
    # Read first line to check format
    local firstLine
    read -r firstLine < "$DATA_FILE"
    
    # Check if it's the legacy format (just a number for studentCount)
    if [[ "$firstLine" =~ ^[0-9]+$ ]]; then
        legacyFormat=true
        studentCount=$firstLine
    fi
    
    if [ "$legacyFormat" = true ]; then
        # Handle legacy format
        # Read each student's data
        for ((i=0; i<studentCount; i++)); do
            read -r students_rollNo[$i]
            read -r students_name[$i]
            read -r students_password[$i]
            read -r students_totalCourses[$i]
            read -r students_cgpa[$i]
            read -r students_isActive[$i]
            
            # Read course data
            local courseStartIdx=$((i * 5))
            
            for ((j=0; j<${students_totalCourses[$i]}; j++)); do
                read -r courses_name[$courseStartIdx + $j]
                read -r courses_marks[$courseStartIdx + $j]
                read -r courses_grade[$courseStartIdx + $j]
                read -r courses_gradePoints[$courseStartIdx + $j]
            done
        done < <(tail -n +2 "$DATA_FILE")  # Skip the first line (studentCount)
    else
        # Handle new tabular format
        local currentStudent=-1
        local courseCount=0
        
        # Read file line by line
        while IFS= read -r line || [ -n "$line" ]; do
            # Skip comments and separators
            [[ "$line" =~ ^#.*$ ]] && continue
            
            # Split the line by pipe delimiter
            IFS='|' read -r recordType data1 data2 data3 data4 data5 data6 <<< "$line"
            
            if [ "$recordType" = "STUDENT" ]; then
                # New student record
                ((currentStudent++))
                students_rollNo[$currentStudent]=$data1
                students_name[$currentStudent]=$data2
                students_password[$currentStudent]=$data3
                students_totalCourses[$currentStudent]=$data4
                students_cgpa[$currentStudent]=$data5
                students_isActive[$currentStudent]=$data6
                
                # Reset course count for new student
                courseCount=0
            elif [ "$recordType" = "COURSE" ] && [ $currentStudent -ge 0 ]; then
                # Course record for current student
                local courseIdx=$((currentStudent * 5 + courseCount))
                
                courses_name[$courseIdx]=$data1
                courses_marks[$courseIdx]=$data2
                courses_grade[$courseIdx]=$data3
                courses_gradePoints[$courseIdx]=$data4
                
                # Increment the course count
                ((courseCount++))
            fi
        done < "$DATA_FILE"
        
        # Update student count
        studentCount=$((currentStudent + 1))
    fi
}

# Function for student to view their grades
viewStudentGrades() {
    local studentIdx=$1
    
    clear
    echo "===================================="
    echo "        YOUR GRADES AND CGPA        "
    echo "===================================="
    
    echo "Name: ${students_name[$studentIdx]}"
    echo "Roll Number: ${students_rollNo[$studentIdx]}"
    echo "CGPA: ${students_cgpa[$studentIdx]}"
    
    echo -e "\n%-20s %-10s %-5s"
    echo "---------------------------------------"
    
    local courseStartIdx=$((studentIdx * 5))
    
    for ((i=0; i<${students_totalCourses[$studentIdx]}; i++)); do
        printf "%-20s %-10.2f %-5s\n" \
            "${courses_name[$courseStartIdx + $i]}" \
            "${courses_marks[$courseStartIdx + $i]}" \
            "${courses_grade[$courseStartIdx + $i]}"
    done
    
    read -p $'\nPress Enter to continue...'
}

# Load data from file when program starts
loadData

# Main program loop
while true; do
    if [ "$userType" -eq 0 ]; then
        displayMainMenu
        read -p "Enter your choice: " choice
        
        case $choice in
            1) # Login
                clear
                echo "===== LOGIN ====="
                read -p "Enter User ID: " userId
                read -p "Enter Password: "  password
                echo
                
                userType=$(authenticateUser "$userId" "$password")
                
                if [ "$userType" -eq 0 ]; then
                    read -p "Invalid credentials! Press Enter to continue..."
                elif [ "$userType" -eq 2 ]; then
                    # Find student index
                    for ((i=0; i<studentCount; i++)); do
                        if [ "${students_rollNo[$i]}" == "$userId" ] && [ "${students_isActive[$i]}" -eq 1 ]; then
                            studentIndex=$i
                            break
                        fi
                    done
                fi
                ;;
                
            2) # Exit
                echo "Thank you for using Student Management System!"
                exit 0
                ;;
                
            *)
                read -p "Invalid choice! Press Enter to continue..."
        esac
    elif [ "$userType" -eq 1 ]; then # Teacher menu
        displayTeacherMenu
        read -p "Enter your choice: " choice
        
        case $choice in
            1) addStudent ;;
            2) viewStudentDetails ;;
             3) updateStudentInfo ;;
            4) deleteStudent ;;
            5) assignMarks ;;
            6) generateReport 1 ;;  # Ascending
            7) generateReport 2 ;;  # Descending
            8) listPassedStudents ;;
            9) listFailedStudents ;;
            10) 
                saveData
                read -p "Data saved successfully! Press Enter to continue..."
                ;;
            11) 
                userType=0
                read -p "Logged out successfully! Press Enter to continue..."
                ;;
            *)
                read -p "Invalid choice! Press Enter to continue..."
        esac
    elif [ "$userType" -eq 2 ] && [ "$studentIndex" -ne -1 ]; then # Student menu
        displayStudentMenu
        read -p "Enter your choice: " choice
        
        case $choice in
            1) viewStudentGrades "$studentIndex" ;;
            2) 
                userType=0
                studentIndex=-1
                read -p "Logged out successfully! Press Enter to continue..."
                ;;
            *)
                read -p "Invalid choice! Press Enter to continue..."
        esac
    fi
done