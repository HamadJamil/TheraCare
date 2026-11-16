import { logger } from '../config/logger';

type Job = { name: string; everyMs: number; run: () => Promise<unknown> };

/** Minimal in-process scheduler: each job runs serially, never overlapping itself. */
export function startJobs(jobs: Job[]) {
  const timers = jobs.map((job) => {
    let busy = false;
    const tick = async () => {
      if (busy) return;
      busy = true;
      try {
        const result = await job.run();
        logger.info({ job: job.name, result }, 'job finished');
      } catch (err) {
        logger.error({ err, job: job.name }, 'job failed');
      } finally {
        busy = false;
      }
    };
    void tick();
    return setInterval(tick, job.everyMs);
  });
  return () => timers.forEach(clearInterval);
}
