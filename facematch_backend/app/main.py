from fastapi import FastAPI, UploadFile, File, HTTPException

from app.face_matcher import compare_faces


app = FastAPI(
    title="Face Match API",
    description="Face similarity matching API using face embeddings",
    version="1.0.0"
)


@app.get("/")
def root():
    return {
        "message": "Face Match API is running"
    }


@app.post("/match")
async def match_faces(
    selfie: UploadFile = File(...),
    reference: UploadFile = File(...)
):
    """
    Compare a selfie with a reference image.
    """

    try:
        # Read uploaded images into memory
        selfie_bytes = await selfie.read()
        reference_bytes = await reference.read()

        # Compare faces
        result = compare_faces(
            selfie_bytes,
            reference_bytes
        )

        return result

    except ValueError as error:

        raise HTTPException(
            status_code=400,
            detail={
                "success": False,
                "message": str(error)
            }
        )

    except Exception as error:

        print("Unexpected error:", error)

        raise HTTPException(
            status_code=500,
            detail={
                "success": False,
                "message": "An unexpected error occurred."
            }
        )