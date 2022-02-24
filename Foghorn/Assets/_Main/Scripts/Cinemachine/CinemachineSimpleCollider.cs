using UnityEngine;

namespace Cinemachine
{
    /// <summary>
    /// </summary>
    [AddComponentMenu("")] // Hide in menu
    [SaveDuringPlay]
    [ExecuteAlways]
    [DisallowMultipleComponent]
    public class CinemachineSimpleCollider : CinemachineExtension
    {
        /// <summary>Objects on these layers will be detected.</summary>
        [Header("Obstacle Detection")]
        [Tooltip("Objects on these layers will be detected")]
        public LayerMask m_CollideAgainst = 1;

        /// <summary>Obstacles with this tag will be ignored.  It is a good idea to set this field to the target's tag</summary>
        [TagField]
        [Tooltip("Obstacles with this tag will be ignored.  It is a good idea to set this field to the target's tag")]
        public string m_IgnoreTag = string.Empty;

        [Tooltip("How fast to return to distance after collision, higher is faster")]
        [Range(1, 100)]
        public float m_ReturnAfterCollisionRate = 5f;

        /// <summary>Objects on these layers will never obstruct view of the target.</summary>
        [Tooltip("Objects on these layers will never obstruct view of the target")]
        public LayerMask m_TransparentLayers = 0;

        public bool FoundCollision(ICinemachineCamera vcam)
        {
            var extra = GetExtraState<VcamExtraState>(vcam);
            return (Time.time - extra.lastCollideTime < 0.1f);
        }

        void OnValidate()
        {
        }

        /// <summary>
        /// Per-vcam extra state info
        /// </summary>
        class VcamExtraState
        {
            public float lastCollideTime;
            public float currentReturnRate;
            public float previousAdjustment = 5f;
        }

        RaycastHit[] m_RaycastBuffer = new RaycastHit[4];

        /// <summary>Callback to preform the zoom adjustment</summary>
        /// <param name="vcam">The virtual camera being processed</param>
        /// <param name="stage">The current pipeline stage</param>
        /// <param name="state">The current virtual camera state</param>
        /// <param name="deltaTime">The current applicable deltaTime</param>
        protected override void PostPipelineStageCallback(
            CinemachineVirtualCameraBase vcam,
            CinemachineCore.Stage stage, ref CameraState state, float deltaTime)
        {
            var extra = GetExtraState<VcamExtraState>(vcam);

            // Set the zoom after the body has been positioned, but before the aim,
            // so that composer can compose using the updated fov.
            if (stage == CinemachineCore.Stage.Body)
            {
                Vector3 cameraPos = state.CorrectedPosition;
                Vector3 lookAtPos = state.ReferenceLookAt;

                int layerMask = m_CollideAgainst & ~m_TransparentLayers;

                Vector3 displacement = Vector3.zero;
                Vector3 targetToCamera = cameraPos - lookAtPos;
                Ray targetToCameraRay = new Ray(lookAtPos, targetToCamera);
                Vector3 targetToCameraNormalized = targetToCamera.normalized;

                float distToCamera = targetToCamera.magnitude;
                if (distToCamera > Epsilon)
                {
                    float desiredDistToCamera = distToCamera;

                    int numFound = Physics.SphereCastNonAlloc(
                        lookAtPos, 0.1f, targetToCameraNormalized, m_RaycastBuffer, distToCamera + 1f, // Trace back a bit, in case we 'will' collide next frame
                        layerMask, QueryTriggerInteraction.Ignore);
                    if (numFound > 0)
                    {
                        float bestDist = distToCamera;
                        for (int i = 0; i < numFound; ++i)
                        {
                            var castHitInfo = m_RaycastBuffer[i];
                            Vector3 castPoint = castHitInfo.point;//Vector3.Project(castHitInfo.point, targetToCameraNormalized);
                            float dist = Vector3.Distance(lookAtPos, castPoint);
                            if (dist < bestDist)
                            {
                                bestDist = dist;
                            }
                        }

                        if (bestDist < distToCamera)
                        {
                            extra.lastCollideTime = Time.time;
                            extra.currentReturnRate = 0f;
                            desiredDistToCamera = bestDist;
                        }
                    }

                    if (extra.previousAdjustment > desiredDistToCamera)
                    {
                        extra.previousAdjustment = desiredDistToCamera;
                    }
                    else
                    {
                        // Add an extra lerp up to full value to make it buttery
                        extra.currentReturnRate = Mathf.Lerp(extra.currentReturnRate, m_ReturnAfterCollisionRate, 5f * Time.deltaTime);
                        extra.previousAdjustment = Mathf.Lerp(extra.previousAdjustment, desiredDistToCamera, extra.currentReturnRate * Time.deltaTime);
                    }

                    displacement = targetToCameraRay.GetPoint(extra.previousAdjustment) - cameraPos;
                }

                state.PositionCorrection += displacement;
            }
        }
    }
}