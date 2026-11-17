"""
Project Management Routes
Handles projects, tasks, sprints, and team collaboration
"""

from fastapi import APIRouter, HTTPException, status
from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel

router = APIRouter(prefix="/api/projects", tags=["Project Management"])

# ==================== MODELS ====================

class ProjectCreate(BaseModel):
    name: str
    description: str
    start_date: datetime
    end_date: Optional[datetime] = None
    owner_id: str
    team_ids: List[str] = []

class ProjectResponse(BaseModel):
    id: str
    name: str
    description: str
    start_date: datetime
    end_date: Optional[datetime] = None
    status: str  # planning, active, on-hold, completed
    owner_id: str
    team_ids: List[str]
    tasks_count: int = 0
    completed_tasks: int = 0
    progress: float = 0.0

class TaskCreate(BaseModel):
    project_id: str
    title: str
    description: str
    assigned_to: Optional[str] = None
    priority: str  # low, medium, high, urgent
    due_date: Optional[datetime] = None

class TaskResponse(BaseModel):
    id: str
    project_id: str
    title: str
    description: str
    status: str  # todo, in-progress, review, done
    priority: str
    assigned_to: Optional[str] = None
    due_date: Optional[datetime] = None
    created_date: datetime
    completed_date: Optional[datetime] = None

class TaskStatusUpdate(BaseModel):
    status: str

# ==================== PROJECTS ====================

@router.post("/", response_model=ProjectResponse, status_code=status.HTTP_201_CREATED)
async def create_project(project: ProjectCreate):
    """Create new project"""
    try:
        project_data = {
            "id": f"proj_{datetime.now().timestamp()}",
            **project.model_dump(),
            "status": "planning",
            "tasks_count": 0,
            "completed_tasks": 0,
            "progress": 0.0,
        }
        return ProjectResponse(**project_data)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/", response_model=List[ProjectResponse])
async def get_projects(status: Optional[str] = None, owner_id: Optional[str] = None):
    """Get all projects"""
    try:
        # TODO: Database integration
        return []
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{project_id}", response_model=ProjectResponse)
async def get_project(project_id: str):
    """Get project by ID"""
    try:
        # TODO: Database integration
        raise HTTPException(status_code=404, detail="Project not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.put("/{project_id}/status")
async def update_project_status(project_id: str, status: str):
    """Update project status"""
    try:
        # TODO: Database integration
        return {"success": True, "project_id": project_id, "status": status}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ==================== TASKS ====================

@router.post("/tasks", response_model=TaskResponse, status_code=status.HTTP_201_CREATED)
async def create_task(task: TaskCreate):
    """Create new task"""
    try:
        task_data = {
            "id": f"task_{datetime.now().timestamp()}",
            **task.model_dump(),
            "status": "todo",
            "created_date": datetime.now(),
            "completed_date": None,
        }
        return TaskResponse(**task_data)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/tasks", response_model=List[TaskResponse])
async def get_tasks(
    project_id: Optional[str] = None,
    assigned_to: Optional[str] = None,
    status: Optional[str] = None
):
    """Get tasks with filters"""
    try:
        # TODO: Database integration
        return []
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/tasks/{task_id}", response_model=TaskResponse)
async def get_task(task_id: str):
    """Get task by ID"""
    try:
        # TODO: Database integration
        raise HTTPException(status_code=404, detail="Task not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.put("/tasks/{task_id}/status")
async def update_task_status(task_id: str, update: TaskStatusUpdate):
    """Update task status"""
    try:
        # TODO: Database integration
        return {"success": True, "task_id": task_id, "status": update.status}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.put("/tasks/{task_id}/assign")
async def assign_task(task_id: str, user_id: str):
    """Assign task to user"""
    try:
        # TODO: Database integration
        return {"success": True, "task_id": task_id, "assigned_to": user_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ==================== KANBAN ====================

@router.get("/{project_id}/board")
async def get_kanban_board(project_id: str):
    """Get Kanban board for project"""
    try:
        return {
            "project_id": project_id,
            "columns": [
                {"id": "todo", "title": "To Do", "tasks": []},
                {"id": "in-progress", "title": "In Progress", "tasks": []},
                {"id": "review", "title": "Review", "tasks": []},
                {"id": "done", "title": "Done", "tasks": []},
            ]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ==================== ANALYTICS ====================

@router.get("/{project_id}/analytics")
async def get_project_analytics(project_id: str):
    """Get project analytics"""
    try:
        return {
            "total_tasks": 45,
            "completed_tasks": 23,
            "in_progress_tasks": 15,
            "overdue_tasks": 3,
            "completion_rate": 51.1,
            "average_completion_time": 3.5,  # days
            "team_productivity": 85.2,
            "velocity": 12.5  # story points per sprint
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
